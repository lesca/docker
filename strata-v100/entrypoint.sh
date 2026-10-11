#!/bin/bash

export MODEL="${MODEL:-IQ2_XS}"
export PORT="${PORT:-18080}"
export HOST="${HOST:-0.0.0.0}"
export STRATA_DATA="${STRATA_DATA:-/data}"
export FAMILY="${FAMILY:-qwen}"
export CONTEXT="${CONTEXT:-32768}"
export VISION="${VISION:-no}"         # no | yes | cpu (the image encoder on the CPU)
export API_KEY="${API_KEY:-}"
export KV="${KV:-}"                    # int8 | q4_0 | k8v4; empty: setup.py's own default (int8)
export GPUS="${GPUS:-}"                # "0,2" or "all": one model across several cards (docs/MULTI_GPU.md)
export GPU="${GPU:-}"                  # one card, numbered as nvidia-smi numbers them
export LAYER_SPLIT="${LAYER_SPLIT:-}"  # with GPUS: where each later card's layers start (default: auto)
export LOW_RAM="${LOW_RAM:-auto}"      # on: the experts come from the pack's experts.bin, not from RAM
export GGUF_DIR="${GGUF_DIR:-}"        # a mounted folder with GGUF files you already have: no download
export RESIDENT_BUDGET_GIB="${RESIDENT_BUDGET_GIB:-}"   # UD-Q4_K_XL: GiB of experts kept in RAM (default: setup's pick)
export KV_STREAMING="${KV_STREAMING:-}" # auto | on | off; empty: setup.py's own default (auto)

# additional arguments
export STRATA_ARGS="${STRATA_ARGS:-}"

# update root password
export ROOT_PASSWD="${ROOT_PASSWD:-password}"
echo "root:${ROOT_PASSWD}" | chpasswd

# exec "$@"
if [ -n "$1" ]; then
  exec "$@"
  exit 0
fi

# set "$@"
set -- --family "$FAMILY" \
      --model "$MODEL" \
      --context "$CONTEXT" \
      --vision "$VISION" \
      --data-dir "$STRATA_DATA" \
      --host "$HOST" \
      --api-key "$API_KEY" \
      --port "$PORT" \
      --low-ram "$LOW_RAM" \
      $STRATA_ARGS

# set additional arguments
if [ -n "$KV" ]; then set -- "$@" --kv "$KV"; fi
if [ -n "$GPUS" ]; then set -- "$@" --gpus "$GPUS"; fi
if [ -n "$GPU" ]; then set -- "$@" --gpu "$GPU"; fi
if [ -n "$LAYER_SPLIT" ]; then set -- "$@" --layer-split "$LAYER_SPLIT"; fi
if [ -n "$GGUF_DIR" ]; then set -- "$@" --gguf-dir "$GGUF_DIR"; fi
if [ -n "$RESIDENT_BUDGET_GIB" ]; then set -- "$@" --resident-budget-gib "$RESIDENT_BUDGET_GIB"; fi
if [ -n "$KV_STREAMING" ]; then set -- "$@" --kv-streaming "$KV_STREAMING"; fi


echo "[INFO] Starting service: $@"
echo -n "Starting service in "
for i in {3..1}; do
    echo -n "$i "
    sleep 1
done
echo "0! Starting now..."
.venv/bin/python setup.py --setup --yes "$@"
