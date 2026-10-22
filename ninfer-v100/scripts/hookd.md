# hookd.py 说明

访问 http://127.0.0.1:8081 可以在网页中启听服务。

## 无鉴权（`HOOKD_TOKEN` 为空，仅开发/内网）

```bash
# 查看服务状态（running/stopped + pid + uptime）
curl -s http://127.0.0.1:8081/status
# -> {"state": "running", "pid": 12345, "uptime_s": 87.2}

# 停止服务（SIGTERM 进程组，轮询≤15s，未死则 SIGKILL；无进程时 no-op）
curl -s -X POST http://127.0.0.1:8081/stop

# 启动服务（已 running 时返回 409 幂等拒绝）
curl -s -X POST http://127.0.0.1:8081/start

# 重启 = 先 stop 后 start
curl -s -X POST http://127.0.0.1:8081/restart
```

## 带鉴权（生产：`HOOKD_TOKEN=your-secret`）

所有端点都要求 `Authorization: Bearer <token>`，缺失或错误返回 `401`。

```bash
TOKEN=your-secret
API=http://127.0.0.1:8081

curl -s -H "Authorization: Bearer $TOKEN" $API/status
curl -s -X POST -H "Authorization: Bearer $TOKEN" $API/stop
curl -s -X POST -H "Authorization: Bearer $TOKEN" $API/start
curl -s -X POST -H "Authorization: Bearer $TOKEN" $API/restart
```

## 查看 HTTP 状态码 / 判断结果

`/start` 返回 `202`（已启动）或 `409`（已在跑）；`/stop`、`/restart` 返回 `200`/`202`。用 `-w` 打印状态码方便脚本判断：

```bash
# 启动并显示状态码
curl -s -o /dev/null -w "start -> %{http_code}\n" -X POST http://127.0.0.1:8081/start
# start -> 202   （若已在跑则是 409）

# 状态机判断：stopped 才允许 start
STATE=$(curl -s http://127.0.0.1:8081/status | python3 -c 'import sys,json;print(json.load(sys.stdin)["state"])')
[ "$STATE" = "stopped" ] && curl -s -X POST http://127.0.0.1:8081/start
```

## 外部机器访问（webhook 监听 `0.0.0.0`）

容器用 `-p 8081:8081` 发布后，在宿主机或别的机器上直接用容器 IP/域名：

```bash
curl -s http://<container-host>:8081/status
curl -s -X POST http://<container-host>:8081/restart
```

> 提醒：webhook 外部可达，生产环境务必设置 `HOOKD_TOKEN` 并配合防火墙只放行受信任网段。