#!/bin/bash

export MODEL="${MODEL:-/models/qwen3_8_27b_nvfp4.ninfer}"
export PORT="${PORT:-18080}"
export HOST="${HOST:-0.0.0.0}"
export REASONING_EFFORT="${REASONING_EFFORT:-xhigh}" # allow: low, medium, xhigh
export MAX_TOKENS="${MAX_TOKENS:-32768}"
export MAX_CONTEXT="${MAX_CONTEXT:-240000}"
export MAX_CONCURRENCY="${MAX_CONCURRENCY:-1}"

echo "Use model: $MODEL"

# if $@ exisit then exec $@
if [ -n "$1" ]; then
  exec "$@"
else
  ninfer-serve $MODEL \
    --max-context $MAX_CONTEXT \
    --prefill-chunk 2048 \
    --kv-capacity auto \
    --max-concurrency $MAX_CONCURRENCY \
    --kv-dtype int8 \
    --device-state-slots 1 \
    --host-state-slots 8 \
    --host-kv-mib 8192 \
    --spec mtp --draft-tokens 4 \
    --lm-head-draft \
    --preserve-thinking \
    --default-reasoning-effort $REASONING_EFFORT \
    --vision \
    --port $PORT \
    --host $HOST \
    --default-max-tokens $MAX_TOKENS 
fi
