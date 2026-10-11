#!/bin/bash
# 环境变量
export PROJECT_NAME="strata-v100"
export PROJECT_REPO=${1:-strata}
export PROJECT_REPO_PATH="$PROJECT_NAME/$PROJECT_REPO"
export VIRTUAL_ENV=".venv"

if [ "$PROJECT_REPO" == "strata" ]; then
  export GIT_REPO_URL="https://github.com/Niko1221/Strata"
elif [ "$PROJECT_REPO" == "strata-v100" ]; then
  export GIT_REPO_URL="https://github.com/jmnargi/Strata-V100"
fi


# 克隆仓库
if [ ! -d "$PROJECT_REPO_PATH" ]; then
  git clone $GIT_REPO_URL $PROJECT_REPO_PATH
  pushd $PROJECT_REPO_PATH
  export LLAMA_CPP_COMMIT=3cf03257f219afbe7334045ff7c6a06ac68c627d
  wget https://github.com/ggml-org/llama.cpp/archive/$LLAMA_CPP_COMMIT.zip -O llama.cpp.zip
  unzip -qq "llama.cpp.zip" -d third_party -x '*/tools/ui/*'
  mv "third_party/llama.cpp-$LLAMA_CPP_COMMIT" third_party/llama.cpp
  popd
fi

# Build docker image
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "building docker image ..."
    docker buildx build \
      --progress=plain \
      --build-arg PROJECT_REPO=$PROJECT_REPO \
      --build-arg PIP_INDEX_URL=https://mirrors.bfsu.edu.cn/pypi/web/simple \
      -t "lesca/${PROJECT_NAME}:latest" \
      -f $PROJECT_NAME/Dockerfile $PROJECT_NAME
fi