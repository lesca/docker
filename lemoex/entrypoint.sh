#!/bin/bash
# 清除代理环境变量，防止 httpx 将 IPv6 地址错误解析为 port
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
unset ALL_PROXY all_proxy NO_PROXY no_proxy
unset HTTPX_TRUST_ENVIRONMENT

# PyTorch CPU 多线程配置
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(nproc)}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-$(nproc)}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-$(nproc)}"
export NUMEXPR_NUM_THREADS="${NUMEXPR_NUM_THREADS:-$(nproc)}"
export TORCH_NUM_THREADS="${TORCH_NUM_THREADS:-$(nproc)}"

# Python 输出不缓冲
export PYTHONUNBUFFERED=1

# 启动应用
if [ "$1" = "bash" ]; then
  exec "$@"
else
  lemoex /input "$@"
fi