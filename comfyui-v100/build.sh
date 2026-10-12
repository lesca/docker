#!/bin/bash
# 环境变量
export PROJECT_NAME="comfyui-v100"
export PROJECT_REPO=${PROJECT_REPO:-comfyui}
export PROJECT_REPO_PATH="$PROJECT_NAME/src"
export VERSION=${1:-"v0.38.1"}

if [ "$PROJECT_REPO" == "comfyui" ]; then
  export GIT_REPO_URL="https://github.com/comfy-org/comfyui"
fi


# 克隆仓库
if [ ! -d "$PROJECT_REPO_PATH" ]; then
  git clone $GIT_REPO_URL $PROJECT_REPO_PATH/$PROJECT_REPO
  git clone https://github.com/aaalll12322/ComfyUI-MiniMaxH3-SolAttn-V100 $PROJECT_REPO_PATH/ComfyUI-MiniMaxH3-SolAttn-V100
else
  git -C $PROJECT_REPO_PATH/$PROJECT_REPO pull
fi

# Build docker image
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "building docker image ..."
    docker buildx build \
      --progress=plain \
      --build-arg PROJECT_REPO=$PROJECT_REPO \
      --build-arg VERSION=$VERSION \
      --build-arg HTTPS_PROXY=http://172.17.0.1:7070 \
      -t "lesca/${PROJECT_NAME}:latest" \
      -f $PROJECT_NAME/Dockerfile $PROJECT_NAME
fi