#!/bin/bash

export MODEL="${MODEL:-/models/ninfer-new/qwen3_8_27b_merkyor_coder390_nvfp4.ninfer}"
export PORT="${PORT:-18080}"
export HOST="${HOST:-0.0.0.0}"
export DRAFT_TOKENS="${DRAFT_TOKENS:-5}"
export MAX_TOKENS="${MAX_TOKENS:-32768}"
export MAX_CONCURRENCY="${MAX_CONCURRENCY:-1}"
export MAX_CONTEXT="${MAX_CONTEXT:-240000}"
export PENDING_TIMEOUT="${PENDING_TIMEOUT:-120000}"

# Device checkpoint slots beyond the active lanes (the engine's own default is
# max-concurrency; keep 1 for a single lane, 2+ when serving several).
export DEVICE_STATE_SLOTS="${DEVICE_STATE_SLOTS:-$MAX_CONCURRENCY}"

export NINFER_ARGS="${NINFER_ARGS:-}"

# update root password
export ROOT_PASSWD="${ROOT_PASSWD:-password}"
echo "root:${ROOT_PASSWD}" | chpasswd

# `docker run image <cmd>` override branch keeps the original semantics:
# the custom command runs instead, and hookd is NOT started.
if [ -n "$1" ]; then
  exec "$@"
  exit 0
fi

# Full service command line for hookd. Single quotes keep the variable
# references literal; hookd executes it via `sh -c`, so they expand against
# the exported environment above ($NINFER_ARGS passthrough preserved).
export HOOKD_CMD='ninfer-serve "$MODEL" \
--max-context $MAX_CONTEXT \
--prefill-chunk 2048 \
--kv-capacity auto \
--max-concurrency $MAX_CONCURRENCY \
--pending-timeout-ms $PENDING_TIMEOUT \
--kv-dtype int8 \
--device-state-slots $DEVICE_STATE_SLOTS \
--host-state-slots 8 \
--host-kv-mib 8192 \
--spec mtp \
--draft-tokens $DRAFT_TOKENS \
--lm-head-draft \
--preserve-thinking \
--vision \
--port $PORT \
--host $HOST \
--default-max-tokens $MAX_TOKENS \
$NINFER_ARGS'

echo "[INFO] Use model: $MODEL  (C=$MAX_CONCURRENCY, ctx=$MAX_CONTEXT, K=$DRAFT_TOKENS)"
echo "[INFO] hookd will launch the service; webhook on 0.0.0.0:${HOOKD_PORT:-18081}"

# hookd becomes PID 1 (supervisor + webhook); the service runs in its own
# session/process group and is managed through the webhook.
exec python3 /opt/scripts/hookd.py
