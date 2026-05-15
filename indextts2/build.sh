#!/bin/bash
# 环境变量
export PROJECT_NAME="indextts2"
export MODEL_DIR="$PROJECT_NAME/models"
export VIRTUAL_ENV=".venv"

# 克隆 index-tts 仓库
git clone --single-branch --branch main --depth 1 https://github.com/index-tts/index-tts.git $PROJECT_NAME/index-tts
# git lfs install --local
# git lfs pull

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
if [ "$GITHUB_ACTIONS" == "true" ]; then
    hf download IndexTeam/IndexTTS-2 --local-dir $MODEL_DIR/IndexTeam/IndexTTS-2
    hf download facebook/w2v-bert-2.0 --local-dir $MODEL_DIR/facebook/w2v-bert-2.0
    hf download amphion/MaskGCT --local-dir $MODEL_DIR/amphion/MaskGCT
    hf download funasr/campplus --local-dir $MODEL_DIR/funasr/campplus
    hf download nvidia/bigvgan_v2_22khz_80band_256x --local-dir $MODEL_DIR/nvidia/bigvgan_v2_22khz_80band_256x
else
    modelscope download IndexTeam/IndexTTS-2 --local_dir $MODEL_DIR/IndexTeam/IndexTTS-2
    modelscope download facebook/w2v-bert-2.0 --local_dir $MODEL_DIR/facebook/w2v-bert-2.0
    modelscope download amphion/MaskGCT --local_dir $MODEL_DIR/amphion/MaskGCT
    hf download funasr/campplus --local-dir $MODEL_DIR/funasr/campplus
    hf download nvidia/bigvgan_v2_22khz_80band_256x --local-dir $MODEL_DIR/nvidia/bigvgan_v2_22khz_80band_256x
fi

# 构建 arm64 镜像 (if not github actions)
if [ -z "$GITHUB_ACTIONS" ]; then
    docker buildx build --platform linux/arm64 -t lesca/${PROJECT_NAME}:latest -f $PROJECT_NAME/Dockerfile $PROJECT_NAME
fi