#!/bin/bash
# 克隆 VoxCPM 仓库
git clone --depth 1 https://github.com/OpenBMB/VoxCPM.git

# 构建 arm64 镜像
docker buildx build --platform linux/arm64 -t lesca/voxcpm2:latest -f Dockerfile .