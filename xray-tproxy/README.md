
## What it does?

* A [XRAY](https://github.com/XTLS/Xray-core) docker image with tproxy support.

## How to use it?

### 1. Setup `xray` inbound

```jsonc
{
  "inbounds": [
    {
      "port": 12345,  // this port must match `XRAY_INBOUND_PORT` env variable
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "followRedirect": true
      },
      "streamSettings": {
        "sockopt": {
          "tproxy": "tproxy"
        }
      }
    },
    { // this inbound is optional but normally useful
      "tag": "socks",
      "port": 7070,
      "protocol": "mixed",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "routeOnly": false
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "allowTransparent": false
      }
    }
  ]
}
```

For the **outbound** settings, check the [DNS redirection](#dns-redirection) section.

### 2. Run `xray-tproxy` with docker-compose

Copy and modify the following `docker-compose.yml` file:

```yaml
services:
  tproxy:
    image: lesca/xray-tproxy:latest
    container_name: tproxy
    restart: unless-stopped
    stop_signal: SIGKILL
    cap_add:
      - NET_ADMIN
    networks:
      tproxyvlan:
        ipv4_address: 192.168.2.2
    environment:
      XRAY_INBOUND_PORT: "12345" # must match inbound port to xray
      LOCAL_DNS: "114.114.114.114"
      RESERVED_IPS: "0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"
    volumes:
      - ./xray:/etc/xray/config
    command: ["xray", "run", "-confdir", "/etc/xray/config"]

networks:
  tproxyvlan:
    name: tproxyvlan
    driver: macvlan
    driver_opts:
      parent: enp1s0 # modify this to match your network interface name
    ipam:
      config: # modify the following content to match your local network env
        - subnet: "192.168.2.0/24"
          ip_range: "192.168.2.64/27"
          gateway: "192.168.2.1"
```

and for the first time,then run:

```bash
docker-compose up
```

You can see the logs. If everything works well, press `Ctrl-C` to close the log. The service still runs in the background.

You can also use `docker-compose logs -f` to see the logs in real time.

If everything goes well, you can run command below without logs:

```bash
docker-comopse up -d 
```


### (Optional) Run `ash` to debug

You can run `docker exec -it tproxy ash` to run `ash` in the container.

If you discover the image without `xray` running and firewall setup, you can use commands below to debug:

```bash
docker run --rm -it --entrypoint ash --cap-add=NET_ADMIN -v $PWD/xray-tproxy:/src lesca/xray-tproxy:latest
```

* `--entrypoint`: override the default entrypoint to `ash`
* `--cap-add=NET_ADMIN`: run with `NET_ADMIN` capability to use `iptables` or `nftables`
* `-v $PWD/xray-tproxy:/src`: map the current directory to `/src` in the container.

## Environment Viariables

All the environment variables that you can set in `docker-compose.yaml` file:

* `LOCAL_DNS`: Local DNS server to be used for Xray first dialing. It has nothing to do with Xray's internal DNS.
  * Default: 114.114.114.114
* `XRAY_INBOUND_PORT`: Xray works in TPROXY mode on this port. The port **must match** the inbound port of xray config.
  * Default: 12345
* `XRAY_INBOUND_MARK`: The fwmark to be used for Xray inbound packets.
  * Default: 0x1
* `ROUTE_TABLE`: Specify a route table number. All packets with fwmark 0x1 (default) will be routed to this table.
  * Default: 100
* `RESERVED_IPS`: Reversed IP ranges. If destination IP is in these ranges, the packets will not be proxyed.
  * Default: "0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"
  * Removing `172.16.0.0/12` makes it possible to access remote docker network via proxy.

> Note: Set these environment variables will override the default ones.

## Important notes

### DNS redirection

* `xray-tproxy` container doesn't serve a DNS service. 
* To protect your DNS requests from leaking, use a **DNS outbound** in xray configuration to make it redirects all requests via proxy.
* In this way, set your devices' DNS server to `114.114.114.114` or `8.8.8.8` has the same result. 
* However, don't use your LAN DNS server, e.g. `192.168.1.1`. The DNS traffic doesn't route to `xray-tproxy`, and thus is not protected. 

Here is an example of **DNS outbound** in xray config:

```json
{
  "outbounds": [
    {
      // your outbound to remote server
      "tag": "proxy",
      // ...
    },
    {
      // DNS outbound via proxy
      "tag": "out-dns",
      "protocol": "dns",
      "settings": {
        "address": "8.8.8.8"
      },
      "proxySettings": {
        "tag": "proxy"
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
```