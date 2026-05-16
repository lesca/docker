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

# 安装依赖
if [ "$TARGETPLATFORM" == "linux/arm64" ]; then
    cp /tmp/pyproject.toml /app/pyproject.toml
    pip install --no-cache-dir torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cpu;
    uv sync --python $VIRTUAL_ENV/bin/python --extra "webui"
    # Patch (use wetext)
    sed -i '121s/.*/        if True:/' indextts/utils/front.py
elif [ "$TARGETPLATFORM" == "linux/amd64" ]; then
    uv sync --python $VIRTUAL_ENV/bin/python --all-extras;
fi
