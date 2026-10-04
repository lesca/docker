#!/bin/bash
# 环境变量
export PROJECT_NAME="ninfer-v100-sm70"
export VIRTUAL_ENV=".venv"

# 克隆仓库
if [ ! -d "$PROJECT_NAME/ninfer-v100-sm70" ]; then
  git clone -b master --single-branch --depth 1 https://github.com/Flo5k5/ninfer-v100-sm70 $PROJECT_NAME/ninfer-v100-sm70
else
  git -C $PROJECT_NAME/ninfer-v100-sm70 pull --depth 1
fi

# Build docker image
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "building docker image ..."
    docker buildx build -t "lesca/${PROJECT_NAME}:latest" -f $PROJECT_NAME/Dockerfile $PROJECT_NAME --progress=plain
fi