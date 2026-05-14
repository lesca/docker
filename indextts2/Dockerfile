FROM --platform=$BUILDPLATFORM python:3.11-trixie AS builder

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

# 复制项目
COPY index-tts /app
WORKDIR /app

# 创建虚拟环境
RUN python -m venv .venv
ENV VIRTUAL_ENV=/app/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH

# 安装 pip 和 uv
RUN pip install --no-cache-dir -U pip \
 && pip install --no-cache-dir -U uv

# 安装依赖
RUN pip install --no-cache-dir torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cpu;
COPY pyproject.toml /app/pyproject.toml
RUN uv sync --python $VIRTUAL_ENV/bin/python --extra "webui" --no-cache-dir --default-index "https://mirrors.aliyun.com/pypi/simple"

# 下载模型
RUN uv tool install --no-cache-dir "huggingface-hub[cli,hf_xet]" \
 && uv tool install --no-cache-dir "modelscope"
RUN modelscope download IndexTeam/IndexTTS-2 --local_dir checkpoints
RUN hf download facebook/w2v-bert-2.0
RUN hf download amphion/MaskGCT
RUN hf download funasr/campplus
RUN hf download nvidia/bigvgan_v2_22khz_80band_256x

# # # Patch (use wetext)
RUN sed -i '121s/.*/        if True:/' indextts/utils/front.py

# ### 最终构建阶段 ###
FROM --platform=$BUILDPLATFORM python:3.11-trixie

# # 安装系统依赖
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

# # 复制构建阶段产物
COPY --from=builder --chown=0:0 --chmod=755 /root/.local /root/.local
COPY --from=builder --chown=0:0 --chmod=755 /root/.cache/huggingface /root/.cache/huggingface
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
