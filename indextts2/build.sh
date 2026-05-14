#!/bin/bash
# 克隆 VoxCPM 仓库
git clone --single-branch --branch main --depth 1 https://github.com/index-tts/index-tts.git
git lfs pull

# 构建 arm64 镜像
docker buildx build --platform linux/arm64 -t lesca/indextts2:latest -f Dockerfile .