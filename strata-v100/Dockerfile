FROM --platform=$BUILDPLATFORM nvidia/cuda:12.8.1-devel-ubuntu24.04 AS builder

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
        libatomic1 \
        libgomp1 \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 STRATA_EXECV=1 
ARG PROJECT_REPO
WORKDIR /opt/strata
COPY $PROJECT_REPO /opt/strata

ARG PIP_INDEX_URL
RUN python3 -m venv .venv \
  && .venv/bin/pip install --no-cache-dir --upgrade pip \
  && .venv/bin/pip install --no-cache-dir -r requirements.txt \
  && chmod +x setup.sh docker-entrypoint.sh

# build strata
RUN cmake -S . -B build-cuda12 -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTRATA_ENABLE_CUDA=ON \
    -DSTRATA_BUILD_TESTS=OFF \
    -DSTRATA_EXPERIMENTAL_SM60=ON \
    -DCMAKE_CUDA_ARCHITECTURES="61;70" \
    -DSTRATA_GGML_DIR=third_party/llama.cpp \
  && cmake --build build-cuda12 --target strata -j

# build strata-vision
RUN cmake -S tools/vision -B build-vision-cuda12 -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_DIR=third_party/llama.cpp \
    -DSTRATA_VISION_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES="61;70" \
  && cmake --build build-vision-cuda12 --target strata-vision -j

# copy artifacts
RUN mkdir -p engine-cuda12 \
  && cp build-cuda12/strata engine-cuda12/ \
  && cp build-vision-cuda12/bin/strata-vision engine-cuda12/ \
  && python3 - <<'PYEOF'
import json, pathlib
import setup
nvcc, _ = setup.find_nvcc()          # 必须是你编译时用的那个 CUDA 12.8 的 nvcc
eng = setup.ROOT / "engine-cuda12"
bindir = pathlib.Path(nvcc).parent
meta = {"source": "local", "version": setup.source_version(),
        "archs": [70], "vision": "gpu", "toolkit": 12,
        "cuda_dirs": [str(d) for d in (bindir, bindir / "x64", bindir.parent / "lib64") if d.is_dir()],
        "src": setup.source_hash(setup.ENGINE_SOURCES),
        "vision_src": setup.source_hash(setup.VISION_SOURCES)}
(eng / "BUILD.json").write_text(json.dumps(meta, indent=1))
PYEOF

# clean up
RUN rm -rf build-cuda12 build-vision-cuda12 llama.cpp.zip

### RUNNER ###
FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04 AS runner

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 STRATA_EXECV=1 
ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_ACTIONS

COPY ubuntu.sources /tmp
RUN if [ -z "$GITHUB_ACTIONS" ]; then \
        cp /tmp/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources; \
    fi

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libatomic1 \
        libgomp1 \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        openssh-server \
    && rm -rf /var/lib/apt/lists/*


COPY --from=builder /opt/strata /opt/strata

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Process copied files
RUN chmod +x /usr/local/bin/entrypoint.sh \
  && mkdir -p /var/run/sshd \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

WORKDIR /opt/strata
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


