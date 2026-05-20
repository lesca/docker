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

# install pip and uv
pip install -U pip uv
pip install huggingface-hub

# install whisperx
echo "install whisperx ..."
pip install -e whisperx
pip uninstall -y torchcodec
pip install soundfile
# pip install torch torchaudio torchvision torchcodec --force-reinstall --index-url https://download.pytorch.org/whl/cu128
# pip install nvidia-npp-cu12 
# export LD_LIBRARY_PATH=/workspace/.venv/lib/python3.11/site-packages/nvidia/npp/lib:$LD_LIBRARY_PATH

# # install lemoex
echo "install lemoex ..."
pip install -e .
