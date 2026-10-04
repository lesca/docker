FROM --platform=$BUILDPLATFORM nvidia/cuda:12.9.2-cudnn-devel-ubuntu24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_ACTIONS

COPY ubuntu.sources /tmp

RUN if [ -z "$GITHUB_ACTIONS" ]; then \
        cp /tmp/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources; \
    fi

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        cmake \
        git \
        python3 \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libcurl4-openssl-dev \
        libswscale-dev \
        ninja-build \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY ninfer-v100-sm70 /src
WORKDIR /src

RUN cmake -S . -B /build -G Ninja \
        -DCMAKE_CUDA_ARCHITECTURES=70 \
        -DCMAKE_BUILD_TYPE=Release \
        -DNINFER_BUILD_APPS=ON \
        -DBUILD_TESTING=OFF \
        -DNINFER_BUILD_BENCHMARKS=OFF \
    && cmake --build /build --parallel --target ninfer ninfer-serve

### RUNNER ###
FROM nvidia/cuda:12.9.2-runtime-ubuntu24.04 AS runner

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_ACTIONS

COPY ubuntu.sources /tmp
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN if [ -z "$GITHUB_ACTIONS" ]; then \
        cp /tmp/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    chmod +x /usr/local/bin/entrypoint.sh

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        libavcodec60 \
        libavformat60 \
        libavutil58 \
        libcurl4t64 \
        libswscale7 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/apps/ninfer /usr/local/bin/ninfer
COPY --from=builder /build/apps/ninfer-serve /usr/local/bin/ninfer-serve

WORKDIR /workspace
EXPOSE 8080
STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


