FROM --platform=$BUILDPLATFORM nvidia/cuda:12.9.2-devel-ubuntu24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_ACTIONS

COPY ubuntu.sources /tmp

RUN if [ -z "$GITHUB_ACTIONS" ]; then \
        cp /tmp/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources; \
    fi

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        ca-certificates \
        curl \
        git \
        python3 \
        python3-pip \
        python3-dev \
        python3-venv \
        unzip \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
ARG PIP_INDEX_URL
ARG HTTPS_PROXY
ARG TARGETARCH
ARG TARGETVARIANT
ARG UV_LINK_MODE=copy
ARG VIRTUAL_ENV=/src/comfyui/.venv
ENV VIRTUAL_ENV=${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

COPY src /src

### ComfyUI ###
WORKDIR /src/comfyui

ARG VERSION
RUN git checkout $VERSION

# setup venv
RUN python3 -m venv .venv

# Install torch
RUN --mount=type=cache,id=pip-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=type=cache,id=uv-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=type=cache,id=torch-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/torch \
  pip install --upgrade pip \
  && pip install uv \
  && pip download torch==2.10.0+cu129 torchvision==0.25.0+cu129 torchaudio==2.10.0+cu129 \
      --index-url https://download.pytorch.org/whl/cu129 \
      -d /root/.cache/torch \
  && uv pip install --no-index --find-links=/root/.cache/torch torch torchvision torchaudio

# Install comfyui
RUN --mount=type=cache,id=pip-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=type=cache,id=uv-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
  uv pip install -r requirements.txt \
  && uv pip install -U --pre comfyui-manager matrix-nio


### ComfyUI-MiniMaxH3-SolAttn-V100 ###
WORKDIR /src/ComfyUI-MiniMaxH3-SolAttn-V100

# build
RUN --mount=type=cache,id=pip-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=type=cache,id=uv-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
  cd native && python setup_linux.py build_ext --inplace

# copy artifacts
RUN mv native/*.so . \
  && rm -rf native/build

### ComfyUI Custom Nodes ###
WORKDIR /src/comfyui/custom_nodes

RUN git clone https://github.com/yolain/Comfyui-Easy-Use.git \
  && git clone https://github.com/r-vage/ComfyUI_Eclipse.git \
  && git clone https://github.com/kijai/ComfyUI-KJNodes.git \
  && git clone https://github.com/kosinkadink/ComfyUI-VideoHelperSuite.git \
  && git clone https://github.com/rgthree/rgthree-comfy.git \
  && git clone https://github.com/phazei/ComfyUI-Enhancement-Utils.git

RUN --mount=type=cache,id=pip-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=type=cache,id=uv-$TARGETARCH-$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
  for f in $(find . -name "requirements.txt"); do echo "Installing requirements.txt: $f"; uv pip install -r "$f"; done

### RUNNER ###
FROM nvidia/cuda:12.9.2-runtime-ubuntu24.04 AS runner

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 STRATA_EXECV=1 PORT=8188
ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_ACTIONS
ARG UV_LINK_MODE=copy
ARG VIRTUAL_ENV=/opt/comfyui/.venv
ENV VIRTUAL_ENV=${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

COPY ubuntu.sources /tmp
RUN if [ -z "$GITHUB_ACTIONS" ]; then \
        cp /tmp/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources; \
    fi

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libxcb1 \
        ffmpeg \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        openssh-server \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Process copied files
RUN mkdir -p /var/run/sshd \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && cat << 'EOF' > /etc/sudoers.d/sudoer_default
ubuntu ALL=(ALL) NOPASSWD: ALL
EOF

ARG USERNAME=ubuntu
USER ${USERNAME}
COPY --from=builder --chown=${USERNAME}:${USERNAME} /src/comfyui /opt/comfyui
COPY --from=builder --chown=${USERNAME}:${USERNAME} /src/ComfyUI-MiniMaxH3-SolAttn-V100 /opt/comfyui/custom_nodes/ComfyUI-MiniMaxH3-SolAttn-V100
COPY scripts /opt/scripts

# Process files
RUN sudo mv /opt/comfyui/custom_nodes /opt/custom_nodes

WORKDIR /opt/comfyui
EXPOSE ${PORT:-8188}

ENTRYPOINT ["bash", "/opt/scripts/entrypoint.sh"]
