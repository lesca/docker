#!/bin/bash

# 定义源目录和目标目录（支持通过命令行参数传入，或使用默认值）
# 用法示例: ./sync_nodes.sh /path/to/source_nodes /opt/comfyui/custom_nodes
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

# 获取目标目录中现有的所有项（转换为小写，存入数组或用于后续匹配）
# 我们直接在循环中动态查找目标目录下的实际文件，实现不区分大小写匹配

# 遍历源目录下的所有项
for item in "$SRC_DIR"/*; do
    # 排除空匹配
    [ -e "$item" ] || continue
    
    item_name=$(basename "$item")
    item_name_lower=$(echo "$item_name" | tr '[:upper:]' '[:lower:]')
    
    # 检查目标目录中是否存在同名节点（不区分大小写）
    found=false
    target_path=""
    
    for dest_item in "$DEST_DIR"/*; do
        [ -e "$dest_item" ] || continue
        dest_item_name=$(basename "$dest_item")
        dest_item_lower=$(echo "$dest_item_name" | tr '[:upper:]' '[:lower:]')
        
        if [ "$item_name_lower" = "$dest_item_lower" ]; then
            found=true
            target_path="$dest_item"
            break
        fi
    done

    # 如果不存在（不区分大小写），则复制
    if [ "$found" = false ]; then
        target_path="$DEST_DIR/$item_name"
        echo "[+] 发现新节点，正在复制: $item_name -> $DEST_DIR"
        cp -a "$item" "$target_path"
    else
        echo "[=] 节点已存在（忽略大小写匹配），跳过: $item_name (实际匹配到: $(basename "$target_path"))"
    fi
done

echo "=========================================="
echo "所有节点检查及同步完成！"