ARG VERSION
FROM --platform=$BUILDPLATFORM ghcr.io/lesca/xray:${VERSION}

# Build xray-core
WORKDIR /src
COPY . . 
ARG TARGETOS
ARG TARGETARCH
RUN  apk update && apk add --no-cache iptables nftables dnsmasq

ENTRYPOINT ["/src/entrypoint.sh"]