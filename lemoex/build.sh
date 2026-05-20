#!/bin/bash
# 环境变量
export PROJECT_NAME="lemoex"
export MODEL_DIR="$PROJECT_NAME/models"
export VIRTUAL_ENV=".venv"

# 克隆仓库
if [ ! -d "$PROJECT_NAME/lemoex" ]; then
  git clone -b main --single-branch --depth 1 --recurse-submodules https://github.com/lesca/lemoex.git $PROJECT_NAME/lemoex
else
  git -C $PROJECT_NAME/lemoex pull --depth 1
fi

# install whisperx
# if [ ! -d "whisperx" ]; then
#   git submodule update --init --recursive --depth 1
# else
#   git submodule deinit -f whisperx
#   git submodule update --init --recursive --depth 1
# fi

# python venv
python3 -m venv $VIRTUAL_ENV
source $VIRTUAL_ENV/bin/activate

# pip 更新 (if not github actions)
if [ -z "$GITHUB_ACTIONS" ]; then
    # pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
    pip config set global.index-url https://mirrors.bfsu.edu.cn/pypi/web/simple
fi

# install pip and uv
pip install -U pip uv
pip install huggingface-hub
pip install demucs

# download models using symlinks
echo "download models ..."
MODELS=(
  "facebook/wav2vec2-large-robust-ft-libri-960h" 
  "pyannote/speaker-diarization-community-1" # requires hf auth login
  "Systran/faster-whisper-small" 
  "Systran/faster-whisper-medium" 
  "Systran/faster-whisper-large-v2" 
  "Systran/faster-whisper-large-v3"
  )
for model in "${MODELS[@]}"; do
    echo "downloading $model ..."
    # HF_HOME=$MODEL_DIR/huggingface python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$model')"
done


# 下载 demucs 模型 (~/.cache/torch/hub/checkpoints)
echo "download demucs model ..."
# TORCH_HOME="$MODEL_DIR/torch" python -c "from demucs.pretrained import get_model; get_model('htdemucs')"

# Build docker image
if [ -z "$GITHUB_ACTIONS" ]; then
    echo "building docker image ..."
    docker buildx build --platform linux/arm64 -t "lesca/${PROJECT_NAME}:latest" -f $PROJECT_NAME/Dockerfile $PROJECT_NAME --progress=plain
fi