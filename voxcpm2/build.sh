#!/bin/bash
# 环境变量
export PROJECT_NAME="voxcpm2"
export MODEL_DIR="$PROJECT_NAME/models"
export VIRTUAL_ENV=".venv"

# 克隆 VoxCPM 仓库
git clone -b main --single-branch --depth 1 https://github.com/OpenBMB/VoxCPM.git $PROJECT_NAME/VoxCPM

# python venv
python3 -m venv $VIRTUAL_ENV
source $VIRTUAL_ENV/bin/activate

# pip 更新 (if not github actions)
if [ -z "$GITHUB_ACTIONS" ]; then
    # pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
    pip config set global.index-url https://mirrors.bfsu.edu.cn/pypi/web/simple
fi
pip install --no-cache-dir -U pip


# 安装 modelscope
pip install --no-cache-dir modelscope
pip install --no-cache-dir huggingface-hub

# 下载模型
if [ "$GITHUB_ACTIONS" == "true" ]; then
    mkdir -p /var/lib/docker/models
    ln -sf /var/lib/docker/models $MODEL_DIR
    hf download OpenBMB/VoxCPM2 --local-dir $MODEL_DIR/OpenBMB/VoxCPM2
    modelscope download iic/SenseVoiceSmall --local-dir $MODEL_DIR/iic/SenseVoiceSmall
    modelscope download iic/speech_zipenhancer_ans_multiloss_16k_base --local-dir $MODEL_DIR/iic/speech_zipenhancer_ans_multiloss_16k_base
else
    modelscope download OpenBMB/VoxCPM2 --local-dir $MODEL_DIR/OpenBMB/VoxCPM2
    modelscope download iic/SenseVoiceSmall --local-dir $MODEL_DIR/iic/SenseVoiceSmall
    modelscope download iic/speech_zipenhancer_ans_multiloss_16k_base --local-dir $MODEL_DIR/iic/speech_zipenhancer_ans_multiloss_16k_base
fi

# 构建 arm64 镜像 (if not github actions)
if [ -z "$GITHUB_ACTIONS" ]; then
    docker buildx build --platform linux/arm64 -t "lesca/${PROJECT_NAME}:latest" -f $PROJECT_NAME/Dockerfile ./$PROJECT_NAME
fi