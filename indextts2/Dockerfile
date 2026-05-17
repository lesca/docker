FROM --platform=$BUILDPLATFORM python:3.11-trixie AS base

# 安装系统依赖
RUN sed -i 's/deb.debian.org/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list.d/debian.sources
# RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update \
 && apt-get install -y \
 wget \
 curl \
 git \
 ffmpeg \
 python3-venv \
 libfst-dev \
 && rm -rf /var/lib/apt/lists/*

### 构建阶段 ###
FROM base AS builder

# 复制项目
COPY index-tts /app
WORKDIR /app

# 设置目标平台
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM
ENV TARGETPLATFORM=$TARGETPLATFORM

# 创建虚拟环境
RUN python -m venv .venv
ENV VIRTUAL_ENV=/app/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH

# 安装依赖
COPY pyproject.toml /tmp/pyproject.toml
COPY requirements.sh /tmp/requirements.sh
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    bash /tmp/requirements.sh

### 最终构建阶段 ###
FROM base AS runner

# 安装系统依赖
RUN sed -i 's/deb.debian.org/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list.d/debian.sources
# RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update \
 && apt-get install -y \
 wget \
 curl \
 git \
 ffmpeg \
 python3-venv \
 libfst-dev \
 && rm -rf /var/lib/apt/lists/*

# 复制模型
COPY models/IndexTeam/IndexTTS-2 /app/checkpoints
COPY models/facebook/w2v-bert-2.0 /root/.cache/huggingface/hub/models/facebook/w2v-bert-2.0
COPY models/amphion/MaskGCT /root/.cache/huggingface/hub/models/amphion/MaskGCT
COPY models/funasr/campplus /root/.cache/huggingface/hub/models/funasr/campplus
COPY models/nvidia/bigvgan_v2_22khz_80band_256x /root/.cache/huggingface/hub/models/nvidia/bigvgan_v2_22khz_80band_256x

# 复制构建阶段产物
COPY --from=builder --chown=0:0 --chmod=755 /app /app
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 设置虚拟环境
ENV VIRTUAL_ENV=/app/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH

WORKDIR /app
EXPOSE 7860
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["python", "webui.py"]
