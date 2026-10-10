#!/bin/bash
# 环境变量
export PROJECT_NAME="ninfer-v100"
export PROJECT_REPO=${1:-"ninfer-v100-sm70"}
export PROJECT_REPO_PATH="$PROJECT_NAME/$PROJECT_REPO"
export VIRTUAL_ENV=".venv"

if [ "$PROJECT_NAME" == "ninfer-v100" ]; then
  export GIT_REPO_URL="https://github.com/geoffwatts/ninfer-v100"
elif [ "$PROJECT_NAME" == "ninfer-v100-sm70" ]; then
  export GIT_REPO_URL="https://github.com/Flo5k5/ninfer-v100-sm70"
fi


# 克隆仓库
if [ ! -d "$PROJECT_REPO_PATH" ]; then
  git clone $GIT_REPO_URL $PROJECT_REPO_PATH
else
  git -C $PROJECT_REPO_PATH pull --depth 1
fi

# Build docker image
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "building docker image ..."
    docker buildx build \
      -t "lesca/${PROJECT_REPO}:latest" \
      -f $PROJECT_NAME/Dockerfile $PROJECT_NAME \
      --build-arg PROJECT_REPO=$PROJECT_REPO \
      --progress=plain
fi