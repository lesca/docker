## XRAY docker image by Lesca

This repository provides a docker image for [XRAY](https://github.com/XTLS/Xray-core). It provides 8 CPU architectures, including:

* `linux/386`
* `linux/amd64`
* `linux/arm64`
* `linux/arm/v7`
* `linux/arm/v6`
* `linux/riscv64`
* `linux/ppc64le`
* `linux/s390x`

### Run `XRAY`

To run with `docker-comopse`:

```yaml
services:
  xray:
    image: lesca/xray:latest
    restart: always
    stop_signal: SIGKILL
    network_mode: host
    hostname: xray
    container_name: xray
    volumes:
      - ./config:/etc/xray/config
    command: ["run", "-confdir", "/etc/xray/config"]
```

Or just run command:

```bash
docker run --rm -it -v $PWD/config:/etc/xray/config lesca/xray:latest xray run -confdir /etc/xray/config
```

