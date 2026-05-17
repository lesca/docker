#!/bin/bash

# 环境变量
echo "VIRTUAL_ENV: $VIRTUAL_ENV"
echo "TARGETPLATFORM: $TARGETPLATFORM"
echo "GITHUB_ACTIONS: $GITHUB_ACTIONS"

# 检查 python pip
which python
which pip

# pip 更新 (if not github actions)
if [ -z "$GITHUB_ACTIONS" ]; then
    # pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
    pip config set global.index-url https://mirrors.bfsu.edu.cn/pypi/web/simple
fi

# 安装 pip 和 uv
pip install -U pip uv

# 安装 PyTorch
pip install torch torchaudio torchcodec --index-url https://download.pytorch.org/whl/cu128;

if [ "$TARGETPLATFORM" == "linux/arm64" ]; then
    echo "arm64";
elif [ "$TARGETPLATFORM" == "linux/amd64" ]; then
    echo "amd64";
fi

# 安装项目
uv sync --python $VIRTUAL_ENV/bin/python
pip install -e .

# 安装 nvidia 库
# pip install nvidia-cuda-nvrtc-cu12 nvidia-cuda-runtime-cu12 nvidia-npp-cu12
pip install nvidia-npp-cu12