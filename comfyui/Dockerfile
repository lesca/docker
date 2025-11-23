FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS builder

WORKDIR /app
ARG VERSION
ARG BUILD_MODE

ENV CUDA_HOME=/usr/local/cuda \
    VIRTUAL_ENV=/app/venv \
    PYTHONPYCACHEPREFIX="/root/.cache/pycache"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# install system dependencies
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    apt update \
 && apt install -y --no-install-recommends git curl python3 python3-dev python3-pip python3-venv \
 && rm -rf /var/lib/apt/lists/* \
 && python3 -m venv $VIRTUAL_ENV

# install comfyui dependencies and tools
# https://github.com/Comfy-Org/comfy-cli
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -U pip \
 && pip install torch torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu128 \
 && pip install comfy-cli \
 && comfy --skip-prompt --no-enable-telemetry --here install --nvidia \
 && mkdir -p /app/ComfyUI/user/default/ComfyUI-Manager \
 && cat <<EOF > /app/ComfyUI/user/default/ComfyUI-Manager/config.ini
[default]
use_uv = False
network_mode = offline
EOF

# build Saga Attention
# WORKDIR /build/SageAttention
# ENV TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 9.0"
# RUN git clone --depth 1 --branch v2.2.0 https://github.com/thu-ml/SageAttention.git /build/SageAttention \
#  && export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=16 \
#  && python setup.py install

# install custom nodes
WORKDIR /app/ComfyUI/custom_nodes
COPY nodes nodes
RUN nodes_list=$(sed -e '/^#/d' -e '/^$/d' -e 's/\s*#.*$//' nodes/nodes-${BUILD_MODE}.txt) \
 && for node in $nodes_list; do \
        git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules "https://github.com/$node"; \
    done

# install custom nodes dependencies
# https://github.com/Comfy-Org/ComfyUI-Manager/blob/main/docs/en/cm-cli.md
RUN --mount=type=cache,target=/root/.cache/pip \
    python /app/ComfyUI/custom_nodes/ComfyUI-Manager/cm-cli.py restore-dependencies \
 && nodes_deps=$(sed -e '/^#/d' -e '/^$/d' -e 's/\s*#.*$//' nodes/deps.txt) \
 && for dep in $nodes_deps; do \
        pip install $dep; \
    done \
 && rm -rf nodes


FROM ubuntu:24.04 

WORKDIR /app

ENV CUDA_HOME=/usr/local/cuda \
    VIRTUAL_ENV=/app/venv \
    PYTHONPYCACHEPREFIX="/root/.cache/pycache"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    apt update \
 && apt install -y --no-install-recommends \
    git python3 python3-pip python3-venv ffmpeg rsync aria2 vim \
 && rm -rf /var/lib/apt/lists/* 

COPY --from=builder /app /app
COPY entrypoint.sh /app/entrypoint.sh

EXPOSE 8188
ENTRYPOINT ["/app/entrypoint.sh"]