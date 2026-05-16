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
pip install --no-cache-dir -U pip uv

# 安装 PyTorch
pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cu128;

if [ "$TARGETPLATFORM" == "linux/arm64" ]; then
    echo "arm64";
elif [ "$TARGETPLATFORM" == "linux/amd64" ]; then
    echo "amd64";
fi

# 安装项目
uv sync --no-cache-dir --python $VIRTUAL_ENV/bin/python
pip install --no-cache-dir -e .

