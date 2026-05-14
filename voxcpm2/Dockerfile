FROM --platform=$BUILDPLATFORM python:3.11-trixie AS builder

# 安装系统依赖
# RUN sed -i 's/deb.debian.org/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update \
 && apt-get install -y \
 wget \
 curl \
 git \
 ffmpeg \
 python3-venv \
 && rm -rf /var/lib/apt/lists/*

# 复制 VoxCPM 仓库
COPY VoxCPM /app

WORKDIR /app

# 创建虚拟环境
RUN python -m venv .venv
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 安装 pip 和 uv
RUN pip install --no-cache-dir -U pip \
&& pip install --no-cache-dir -U uv

# 根据平台安装 PyTorch（CPU 版本以确保兼容性）
# Apple Silicon (arm64) 或 x86_64
RUN if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
 pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cpu; \
 pip install --no-cache-dir torchcodec; \
 else \
 pip install --no-cache-dir torch torchaudio; \
 fi

# 安装依赖
RUN sed -i '/torchcodec/d' pyproject.toml \
 && uv sync --no-cache-dir \
 && pip install --no-cache-dir -e .

# 下载模型 (~/.cache/modelscope)
RUN uv tool install --no-cache-dir "modelscope"
RUN modelscope download --model iic/SenseVoiceSmall
RUN modelscope download --model OpenBMB/VoxCPM2 --local_dir checkpoints
RUN modelscope download --model iic/speech_zipenhancer_ans_multiloss_16k_base

### 最终构建阶段 ###
FROM --platform=$BUILDPLATFORM python:3.11-trixie

# 安装系统依赖
# RUN sed -i 's/deb.debian.org/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update \
 && apt-get install -y \
 wget \
 curl \
 git \
 ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# 复制构建阶段产物
COPY --from=builder --chown=0:0 --chmod=755 /app /app
COPY --from=builder --chown=0:0 --chmod=755 /root/.local /root/.local
COPY --from=builder --chown=0:0 --chmod=755 /root/.cache/modelscope /root/.cache/modelscope
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 设置虚拟环境
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /app
EXPOSE 8808
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["python", "app.py", "--model-id", "/app/checkpoints"]