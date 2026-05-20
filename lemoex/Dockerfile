FROM --platform=$BUILDPLATFORM python:3.11-trixie AS base

# 安装系统依赖
# RUN [ -z "$GITHUB_ACTIONS" ] && sed -i 's/deb.debian.org/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN [ -z "$GITHUB_ACTIONS" ] && sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update \
 && apt-get install -y \
 wget \
 curl \
 git \
 ffmpeg \
 python3-venv \
 fonts-noto-cjk \
 && rm -rf /var/lib/apt/lists/*

### 构建阶段 ###
FROM base AS builder

# 复制 VoxCPM 仓库
COPY lemoex /app
WORKDIR /app

# 设置目标平台
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM
ENV TARGETPLATFORM=$TARGETPLATFORM

# 创建虚拟环境
RUN python -m venv .venv
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 安装依赖
COPY requirements.sh /tmp/requirements.sh
RUN --mount=type=cache,id=cache-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache \
    bash /tmp/requirements.sh

### 最终构建阶段 ###
FROM base AS runner

# 复制模型
COPY models/huggingface/hub /root/.cache/huggingface/hub
COPY models/torch /root/.cache/torch

# 复制构建阶段产物
COPY --from=builder --chown=0:0 --chmod=755 /app /app
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 配置字体
COPY 00-prefer-cjk-sc.conf /etc/fonts/conf.d/00-prefer-cjk-sc.conf

# 设置虚拟环境
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
