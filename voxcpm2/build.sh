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

# pip 更新
# pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
pip config set global.index-url https://mirrors.bfsu.edu.cn/pypi/web/simple
pip install --no-cache-dir -U pip


# 安装 modelscope
pip install --no-cache-dir modelscope
pip install --no-cache-dir huggingface-hub

# 下载模型
modelscope download --model OpenBMB/VoxCPM2 --local_dir $MODEL_DIR/OpenBMB/VoxCPM2
modelscope download --model iic/SenseVoiceSmall --local_dir $MODEL_DIR/iic/SenseVoiceSmall
modelscope download --model iic/speech_zipenhancer_ans_multiloss_16k_base --local_dir $MODEL_DIR/iic/speech_zipenhancer_ans_multiloss_16k_base

# 构建 arm64 镜像 (if not github actions)
if [ -z "$GITHUB_ACTIONS" ]; then
    docker buildx build --platform linux/arm64 -t "lesca/${PROJECT_NAME}:latest" -f $PROJECT_NAME/Dockerfile ./$PROJECT_NAME
fi