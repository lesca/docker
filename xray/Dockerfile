# Dockerfile for xray based alpine
# Copyright (C) 2025 Lesca Fang
# Reference URL:
# https://github.com/XTLS/Xray-core/blob/main/.github/docker/Dockerfile
# https://github.com/teddysun/across/blob/master/docker/xray/Dockerfile

# syntax=docker/dockerfile:latest
FROM --platform=$BUILDPLATFORM golang:latest AS build
# FROM --platform=$BUILDPLATFORM public.ecr.aws/docker/library/golang:latest AS build

# Build xray-core
WORKDIR /src
ARG TARGETOS
ARG TARGETARCH
ARG VERSION
RUN  git clone --branch $VERSION https://github.com/XTLS/xray-core.git /src \
  && GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0 go build -o xray -trimpath -ldflags "-s -w -buildid=" ./main

# Build finally image
FROM alpine:latest
# FROM public.ecr.aws/docker/library/alpine:latest

COPY --from=build --chown=0:0 --chmod=755 /src/xray /usr/local/bin/xray

RUN  apk add --no-cache tzdata ca-certificates openssl curl \
  && mkdir -p /usr/local/share/xray /etc/xray /var/log/xray \
  && curl -Lo /usr/local/share/xray/geoip.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat \
  && curl -Lo /usr/local/share/xray/geosite.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat 

ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/usr/local/bin/xray" ]