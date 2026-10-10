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

echo "Use model: $MODEL  (C=$MAX_CONCURRENCY, ctx=$MAX_CONTEXT, K=$DRAFT_TOKENS)"

# update root password
export ROOT_PASSWD="${ROOT_PASSWD:-password}"
echo "root:${ROOT_PASSWD}" | chpasswd

if [ -n "$1" ]; then
  exec "$@"
else
  ninfer-serve "$MODEL" \
    --max-context $MAX_CONTEXT \
    --prefill-chunk 2048 \
    --kv-capacity auto \
    --max-concurrency $MAX_CONCURRENCY \
    --pending-timeout-ms $PENDING_TIMEOUT \
    --kv-dtype int8 \
    --device-state-slots $DEVICE_STATE_SLOTS \
    --host-state-slots 8 \
    --host-kv-mib 8192 \
    --spec mtp --draft-tokens $DRAFT_TOKENS \
    --lm-head-draft \
    --preserve-thinking \
    --vision \
    --port $PORT \
    --host $HOST \
    --default-max-tokens $MAX_TOKENS \
    $NINFER_ARGS
fi