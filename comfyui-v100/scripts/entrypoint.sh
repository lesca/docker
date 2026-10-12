#!/bin/bash

export PORT="${PORT:-8188}"
export HOST="${HOST:-0.0.0.0}"

# additional arguments
export COMFYUI_ARGS="${COMFYUI_ARGS:-}"

# update root password
export ROOT_PASSWD="${ROOT_PASSWD:-password}"
echo "root:${ROOT_PASSWD}" | sudo chpasswd

# exec "$@"
if [ -n "$1" ]; then
  exec "$@"
  exit 0
fi

# prepare dirs
TARGET_UID="${UID:-1000}"
TARGET_GID="${GID:-1000}"
TARGET_DIRS=(
    "/opt/comfyui/models"
    "/opt/comfyui/user"
    "/opt/comfyui/input"
    "/opt/comfyui/output"
    "/opt/comfyui/custom_nodes"
)

for dir in "${TARGET_DIRS[@]}"; do
    # 如果目录不存在，先由 root 创建它
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi

    # 获取当前目录的所有者 UID 和 GID
    current_uid=$(stat -c '%u' "$dir" 2>/dev/null)
    current_gid=$(stat -c '%g' "$dir" 2>/dev/null)

    # 如果所有者不匹配，则修改
    if [ "$current_uid" != "$TARGET_UID" ] || [ "$current_gid" != "$TARGET_GID" ]; then
        echo "[INFO] 权限不匹配，正在修改 chown -R "$TARGET_UID:$TARGET_GID" "$dir" ..."
        sudo chown -R "$TARGET_UID:$TARGET_GID" "$dir"
    fi
done

# sync custom nodes
bash /opt/scripts/sync_custom_nodes.sh

# start service
python3 main.py --listen $HOST --port $PORT \
  --enable-manager \
  --disable-comfy-compiler \
  $COMFYUI_ARGS
