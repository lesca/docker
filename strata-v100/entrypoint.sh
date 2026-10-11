#!/bin/bash

export MODEL="${MODEL:-IQ2_XS}"
export PORT="${PORT:-18080}"
export HOST="${HOST:-0.0.0.0}"
export STRATA_DATA="${STRATA_DATA:-/data}"
export FAMILY="${FAMILY:-qwen}"
export CONTEXT="${CONTEXT:-32768}"
export VISION="${VISION:-yes}"         # no | yes | cpu (the image encoder on the CPU)
export API_KEY="${API_KEY:-}"
export KV="${KV:-}"                    # int8 | q4_0 | k8v4; empty: setup.py's own default (int8)
export GPUS="${GPUS:-}"                # "0,2" or "all": one model across several cards (docs/MULTI_GPU.md)
export GPU="${GPU:-}"                  # one card, numbered as nvidia-smi numbers them
export LAYER_SPLIT="${LAYER_SPLIT:-}"  # with GPUS: where each later card's layers start (default: auto)
export LOW_RAM="${LOW_RAM:-auto}"      # on: the experts come from the pack's experts.bin, not from RAM
export GGUF_DIR="${GGUF_DIR:-}"        # a mounted folder with GGUF files you already have: no download
export RESIDENT_BUDGET_GIB="${RESIDENT_BUDGET_GIB:-}"   # UD-Q4_K_XL: GiB of experts kept in RAM (default: setup's pick)
export KV_STREAMING="${KV_STREAMING:-}" # auto | on | off; empty: setup.py's own default (auto)
export CONFIG="${CONFIG:-}"            # a config file to start with (wins over MODEL's /data/config/strata-<model>.json)


export STRATA_ARGS="${STRATA_ARGS:-}"

echo "Use model: $MODEL"

# update root password
export ROOT_PASSWD="${ROOT_PASSWD:-password}"
echo "root:${ROOT_PASSWD}" | chpasswd

if [ -n "$1" ]; then
  exec "$@"
else
  /opt/strata/docker-entrypoint.sh $STRATA_ARGS
fi