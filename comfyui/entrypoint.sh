#!/usr/bin/bash
PORT=${PORT:-8188}
COMFYIUI_PATH=/app/ComfyUI

# Backup original directory 
if [ -d "/models" ]; then
    echo "[INFO] Moving models to /models..."
    rsync -a $COMFYIUI_PATH/models/ /models/
fi

# create symlink
if [ ! -L "$COMFYIUI_PATH/models" ]; then
    rm -rf $COMFYIUI_PATH/models
    ln -s /models $COMFYIUI_PATH/models
fi

if [ "$#" -eq 0 ]; then
    echo "[INFO] Starting ComfyUI..."
    python $COMFYIUI_PATH/main.py --listen --port $PORT
else
    exec "$@"
fi