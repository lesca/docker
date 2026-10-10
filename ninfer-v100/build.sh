#!/bin/bash
# 环境变量
export PROJECT_NAME="ninfer-v100"
export PROJECT_REPO=${1:-"ninfer-v100-sm70"}
export PROJECT_REPO_PATH="$PROJECT_NAME/$PROJECT_REPO"
export VIRTUAL_ENV=".venv"

if [ "$PROJECT_REPO" == "ninfer-v100" ]; then
  export GIT_REPO_URL="https://github.com/geoffwatts/ninfer-v100"
elif [ "$PROJECT_REPO" == "ninfer-v100-sm70" ]; then
  export GIT_REPO_URL="https://github.com/Flo5k5/ninfer-v100-sm70"
fi


# 克隆仓库
if [ ! -d "$PROJECT_REPO_PATH" ]; then
  git clone $GIT_REPO_URL $PROJECT_REPO_PATH
  pushd $PROJECT_REPO_PATH
  wget https://github.com/NVIDIA/cutlass/archive/refs/tags/v4.4.2.tar.gz -O cutlass-4.4.2.tar.gz
  tar xzf cutlass-4.4.2.tar.gz
  popd
fi

# Build docker image
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "building docker image ..."
    docker buildx build \
      --progress=plain \
      --build-arg PROJECT_REPO=$PROJECT_REPO \
      -t "lesca/${PROJECT_REPO}:latest" \
      -f $PROJECT_NAME/Dockerfile $PROJECT_NAME
fi