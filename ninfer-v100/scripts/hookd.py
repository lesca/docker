#!/usr/bin/env python3
"""hookd — a generic container service supervisor + webhook.

Runs as PID 1 (exec'd from the container entrypoint). It launches the service
command (HOOKD_CMD, executed via `sh -c` so environment variables expand),
supervises it, and exposes a small HTTP webhook to start, stop and restart the
service remotely. Zero coupling with any specific service: everything
service-specific lives in environment variables (HOOKD_CMD and whatever it
references).

Endpoints (all on 0.0.0.0:$HOOKD_PORT, default 18081):
    GET  /         -> control page (Start/Stop/Restart buttons + live status poll);
                      served unauthenticated so the token can be entered on the page
    GET  /status   -> 200 {"state":"stopped|running","pid":...,"uptime_s":...}
    POST /start    -> 202 (started) | 409 (already running)
    POST /stop     -> 200 (SIGTERM the process group, poll <=15s, SIGKILL fallback)
    POST /restart  -> 202 (stop flow + start flow)

No health checks: "running" only means the child process is alive.

Environment:
    HOOKD_CMD        (required, no default) service command line, run via sh -c
    HOOKD_PORT       (default 18081) webhook listen port
    HOOKD_TOKEN      (default "") Bearer token; empty = open access + startup warning
    HOOKD_AUTOSTART  (default 1) launch the service at boot; 0 = webhook-only

PID 1 semantics: on SIGTERM/SIGINT hookd forwards SIGTERM to the service's
process group, waits up to 15s, SIGKILLs the stragglers, then exits 0. If the
service is already stopped, hookd exits immediately. A crashed service leaves
the container alive (state: stopped) and can be /start-ed again. Service logs
inherited stdout -> `docker logs`.
"""

import json
import os
import signal
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STOP_TIMEOUT = 15.0   # max seconds to wait after SIGTERM before SIGKILL
POLL_INTERVAL = 0.2   # polling cadence inside the stop window

ENV_CMD = "HOOKD_CMD"
ENV_PORT = "HOOKD_PORT"
ENV_TOKEN = "HOOKD_TOKEN"
ENV_AUTOSTART = "HOOKD_AUTOSTART"

# Control page. __AUTH__ is replaced with "true"/"false": when true the page
# shows a token field (the browser stores the token in localStorage per origin).
PAGE = """<!doctype html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>hookd</title>
<style>
  :root { color-scheme: dark; }
  body { font: 16px/1.5 system-ui, sans-serif; background: #111; color: #eee;
         display: flex; justify-content: center; padding-top: 15vh; margin: 0; }
  .card { background: #1c1c1c; border: 1px solid #333; border-radius: 12px;
          padding: 24px 28px; min-width: 340px; }
  h1 { font-size: 20px; margin: 0 0 16px; }
  .state { font-size: 40px; font-weight: 700; margin: 8px 0; }
  .state.running { color: #4caf50; }
  .state.stopped { color: #888; }
  .meta { color: #999; margin-bottom: 16px; }
  button { font-size: 15px; padding: 8px 18px; margin-right: 8px; border: 0;
           border-radius: 8px; cursor: pointer; background: #333; color: #eee; }
  button:hover { background: #454545; }
  #msg { color: #999; margin-top: 12px; min-height: 1.5em; }
  #msg.err { color: #e57373; }
  #tokenbox { margin-bottom: 14px; display: none; }
  #tokenbox label { color: #999; font-size: 14px; }
  #tokenbox input { width: 100%; box-sizing: border-box; padding: 6px 8px;
                    border-radius: 6px; border: 1px solid #444; background: #111; color: #eee; }
</style>
</head>
<body>
<div class="card">
  <h1>hookd 服务控制</h1>
  <div id="tokenbox">
    <label>HOOKD_TOKEN</label>
    <input id="token" type="password" placeholder="Bearer token" autocomplete="off">
  </div>
  <div id="state" class="state stopped">…</div>
  <div id="meta" class="meta"></div>
  <div>
    <button onclick="act('start')">启动</button>
    <button onclick="act('stop')">停止</button>
    <button onclick="act('restart')">重启</button>
  </div>
  <div id="msg"></div>
</div>
<script>
const AUTH = __AUTH__;
let token = localStorage.getItem('hookd_token') || '';
const $ = id => document.getElementById(id);
if (AUTH) $('tokenbox').style.display = 'block';
$('token').value = token;
$('token').onchange = () => {
  token = $('token').value.trim();
  localStorage.setItem('hookd_token', token);
  refresh();
};

function headers() {
  const h = {};
  if (token) h['Authorization'] = 'Bearer ' + token;
  return h;
}

async function refresh() {
  try {
    const r = await fetch('/status', {headers: headers()});
    if (r.status === 401) {
      if (AUTH) $('tokenbox').style.display = 'block';
      $('state').textContent = '未授权';
      $('state').className = 'state stopped';
      $('meta').textContent = '';
      $('msg').textContent = '请输入正确的 HOOKD_TOKEN';
      $('msg').className = 'err';
      return;
    }
    const s = await r.json();
    $('state').textContent = s.state;
    $('state').className = 'state ' + s.state;
    $('meta').textContent = s.pid != null ? ('pid ' + s.pid + ' · 运行 ' + s.uptime_s + 's') : '无进程';
    if (!$('msg').className) $('msg').textContent = '';
  } catch (e) {
    $('msg').textContent = '无法连接: ' + e;
    $('msg').className = 'err';
  }
}

async function act(p) {
  const r = await fetch('/' + p, {method: 'POST', headers: headers()});
  $('msg').className = r.ok ? '' : 'err';
  $('msg').textContent = p + ' -> HTTP ' + r.status;
  refresh();
}

refresh();
setInterval(refresh, 2000);
</script>
</body>
</html>
"""


def log(msg):
    print("[hookd] {} {}".format(time.strftime("%Y-%m-%dT%H:%M:%S"), msg), flush=True)


class Supervisor:
    """Owns the service process. Every state mutation is under a lock."""

    def __init__(self, cmd):
        self.cmd = cmd
        self._lock = threading.Lock()
        self._proc = None
        self._started_at = None
        self._exit_logged = False
        self._deliberate_stop = False

    # ---- state ------------------------------------------------------------

    def _alive(self):
        """Caller must hold self._lock."""
        return self._proc is not None and self._proc.poll() is None

    def status(self):
        with self._lock:
            if self._alive():
                return {
                    "state": "running",
                    "pid": self._proc.pid,
                    "uptime_s": round(time.monotonic() - self._started_at, 1),
                }
            return {"state": "stopped", "pid": None, "uptime_s": None}

    # ---- actions ----------------------------------------------------------

    def start(self):
        """Start the service if not running. Returns (started, reason)."""
        with self._lock:
            if self._alive():
                return False, "already running"
            log("starting service: {}".format(self.cmd))
            # shell=True -> 'sh -c $HOOKD_CMD' so env vars expand at run time;
            # start_new_session puts the shell+tree in its own session and
            # process group, so the whole tree is signallable via killpg.
            # stdout/stderr are inherited -> `docker logs`.
            self._proc = subprocess.Popen(self.cmd, shell=True, start_new_session=True)
            self._started_at = time.monotonic()
            self._exit_logged = False
            self._deliberate_stop = False
            log("service started (pid {})".format(self._proc.pid))
            return True, None

    def stop(self, timeout=STOP_TIMEOUT):
        """SIGTERM the process group, poll up to `timeout` s, SIGKILL fallback."""
        deadline = time.monotonic() + timeout
        with self._lock:
            if not self._alive():
                self._proc = None
                log("stop: no service running (no-op)")
                return
            proc = self._proc
            pgid = os.getpgid(proc.pid)
            self._deliberate_stop = True
        log("stop: SIGTERM -> process group {} (pid {})".format(pgid, proc.pid))
        try:
            os.killpg(pgid, signal.SIGTERM)
        except OSError as e:
            log("stop: SIGTERM failed: {}".format(e))
        while time.monotonic() < deadline:
            with self._lock:
                if not self._alive():
                    break
            time.sleep(POLL_INTERVAL)
        with self._lock:
            if self._alive():
                log("stop: still alive after {}s, SIGKILL -> group {}".format(timeout, pgid))
                try:
                    os.killpg(pgid, signal.SIGKILL)
                except OSError as e:
                    log("stop: SIGKILL failed: {}".format(e))
            self._proc.wait()

    # ---- crash detection ----------------------------------------------------

    def monitor(self):
        """Daemon thread: notice the child dying on its own."""
        while True:
            time.sleep(1.0)
            with self._lock:
                if self._proc is not None and self._proc.poll() is not None \
                        and not self._exit_logged:
                    self._exit_logged = True
                    if not self._deliberate_stop:
                        code = self._proc.returncode
                        log("service exited on its own (code {}); container stays alive, /start to relaunch".format(code))


def make_handler(sup, token):
    class Handler(BaseHTTPRequestHandler):
        server_version = "hookd/1.0"

        # -- helpers --
        def _authorized(self):
            if not token:
                return True
            return self.headers.get("Authorization", "") == "Bearer " + token

        def _send(self, code, payload):
            body = json.dumps(payload).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _send_html(self):
            body = PAGE.replace("__AUTH__", "true" if token else "false").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _guard(self):
            if not self._authorized():
                self._send(401, {"error": "unauthorized"})
                return True
            return False

        # -- endpoints --
        def do_GET(self):
            if self.path == "/":
                # The page itself is open: without that a protected instance
                # would not let the user enter the token in the first place.
                self._send_html()
                return
            if self._guard():
                return
            if self.path == "/status":
                self._send(200, sup.status())
            else:
                self._send(404, {"error": "not found"})

        def do_POST(self):
            if self._guard():
                return
            if self.path == "/start":
                started, reason = sup.start()
                self._send(202 if started else 409, sup.status())
            elif self.path == "/stop":
                sup.stop()
                self._send(200, sup.status())
            elif self.path == "/restart":
                sup.stop()
                started, _ = sup.start()
                self._send(202 if started else 500, sup.status())
            else:
                self._send(404, {"error": "not found"})

        def log_message(self, fmt, *args):
            log("http: {} {}".format(self.address_string(), fmt % args))

    return Handler


def main():
    cmd = os.environ.get(ENV_CMD)
    if not cmd:
        log("ERROR: {} is required (no default)".format(ENV_CMD))
        sys.exit(1)
    port = int(os.environ.get(ENV_PORT, "18081"))
    token = os.environ.get(ENV_TOKEN, "")
    autostart = os.environ.get(ENV_AUTOSTART, "1") != "0"

    if not token:
        log("WARNING: {} is empty — webhook is open to anyone".format(ENV_TOKEN))

    sup = Supervisor(cmd)
    threading.Thread(target=sup.monitor, name="monitor", daemon=True).start()

    server = ThreadingHTTPServer(("0.0.0.0", port), make_handler(sup, token))
    server.daemon_threads = True
    threading.Thread(target=server.serve_forever, name="httpd", daemon=True).start()
    log("webhook listening on 0.0.0.0:{} (token {})".format(port, "on" if token else "OFF"))

    if autostart:
        sup.start()

    # PID 1 loop: park until docker stop (SIGTERM) or Ctrl-C (SIGINT).
    # The handler only sets an event so the shutdown runs on the main thread.
    shutdown_event = threading.Event()
    signal.signal(signal.SIGTERM, lambda s, f: shutdown_event.set())
    signal.signal(signal.SIGINT, lambda s, f: shutdown_event.set())
    shutdown_event.wait()
    log("shutting down: forwarding SIGTERM to service, waiting <={}s".format(STOP_TIMEOUT))
    sup.stop(timeout=STOP_TIMEOUT)
    sys.exit(0)


if __name__ == "__main__":
    main()
