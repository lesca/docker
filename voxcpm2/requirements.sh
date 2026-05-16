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

if [ "$TARGETPLATFORM" == "linux/arm64" ]; then
    # 安装 PyTorch（CPU 版本以确保兼容性）
    pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cpu;
    pip install --no-cache-dir torchcodec;
    sed -i '/torchcodec/d' pyproject.toml
elif [ "$TARGETPLATFORM" == "linux/amd64" ]; then
    pip install --no-cache-dir torch torchaudio;
fi

# 安装项目
uv sync --no-cache-dir --python $VIRTUAL_ENV/bin/python
pip install --no-cache-dir -e .

