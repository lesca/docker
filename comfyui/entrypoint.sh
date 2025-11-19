#!/usr/bin/bash
PORT=${PORT:-8188}
COMFYIUI_PATH=/app/ComfyUI
MODELS_PATH=/app/models
CUSTOM_NODES_PATH=/app/custom_nodes

echo "[INFO] Run pre-tasks ..."

### models ###
# Backup models directory 
if [ -d "$MODELS_PATH" ]; then
    echo "[INFO] Moving models to $MODELS_PATH..."
    rsync -a --no-o --no-g $COMFYIUI_PATH/models/ $MODELS_PATH
fi

# create symlink to models
if [ ! -L "$COMFYIUI_PATH/models" ]; then
    rm -rf $COMFYIUI_PATH/models
    ln -s $MODELS_PATH $COMFYIUI_PATH/models
fi

### custom nodes ###
# Backup custom nodes directory if destination is empty
if [ -d "$CUSTOM_NODES_PATH" ] && [ -z "$(ls -A "$CUSTOM_NODES_PATH")" ]; then
    echo "[INFO] Moving custom nodes to $CUSTOM_NODES_PATH ..."
    rsync -a --no-o --no-g $COMFYIUI_PATH/custom_nodes/ $CUSTOM_NODES_PATH
fi

# create symlink to models
if [ ! -L "$COMFYIUI_PATH/custom_nodes" ]; then
    rm -rf $COMFYIUI_PATH/custom_nodes
    ln -s $CUSTOM_NODES_PATH $COMFYIUI_PATH/custom_nodes
fi

### start ###
if [ "$#" -eq 0 ]; then
    echo "[INFO] Starting ComfyUI..."
    python $COMFYIUI_PATH/main.py --listen --port $PORT
else
    exec "$@"
fi