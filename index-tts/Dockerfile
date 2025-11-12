FROM --platform=$BUILDPLATFORM python:3.12.9-bookworm

ENV PATH=/root/.local/bin:$PATH

WORKDIR /app

# 安装系统依赖
RUN apt-get update \
 && apt-get install -y wget curl git git-lfs \
 && rm -rf /var/lib/apt/lists/* \
 && git clone https://github.com/index-tts/index-tts /app \
 && pip install -U uv \
 && git lfs install \
 && git lfs pull \
 && uv sync --all-extras --default-index "https://mirrors.aliyun.com/pypi/simple"

# 下载模型
RUN uv tool install "huggingface-hub[cli,hf_xet]" \
 && hf download funasr/campplus \
 && hf download facebook/w2v-bert-2.0 \
 && hf download amphion/MaskGCT \
 && hf download nvidia/bigvgan_v2_22khz_80band_256x \
 && hf download IndexTeam/IndexTTS-2 --local-dir=checkpoints
 
EXPOSE 7860
CMD ["uv", "run", "webui.py"]
