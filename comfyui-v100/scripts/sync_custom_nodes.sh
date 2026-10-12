#!/bin/bash

# 定义源目录和目标目录（支持通过命令行参数传入，或使用默认值）
# 用法示例: ./sync_nodes.sh /path/to/source_nodes /opt/custom_nodes
SRC_DIR="${1:-/opt/custom_nodes}"
DEST_DIR="${2:-/opt/comfyui/custom_nodes}"

echo "=========================================="
echo "源目录: $SRC_DIR"
echo "目标目录: $DEST_DIR"
echo "=========================================="

# 检查源目录是否存在
if [ ! -d "$SRC_DIR" ]; then
    echo "错误: 源目录 $SRC_DIR 不存在！"
    exit 1
fi

# 确保目标目录存在
if [ ! -d "$DEST_DIR" ]; then
    echo "目标目录不存在，正在创建: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# 遍历源目录下的所有项
for item in "$SRC_DIR"/*; do
    # 排除空匹配
    [ -e "$item" ] || continue
    
    item_name=$(basename "$item")
    target_path="$DEST_DIR/$item_name"

    # 检查目标目录中是否存在该节点
    if [ ! -e "$target_path" ]; then
        echo "[+] 发现新节点，正在复制: $item_name -> $DEST_DIR"
        cp -a "$item" "$target_path"
    else
        echo "[=] 节点已存在，跳过: $item_name"
    fi
done

echo "=========================================="
echo "所有节点检查及同步完成！"