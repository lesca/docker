
## What it does?

* A [XRAY](https://github.com/XTLS/Xray-core) docker image with tproxy support.
* A built-in DNS service. All DNS requests are re-directed to xray to [prevent DNS leaking](#about-dns).

## How to use it?

### 1. Setup `xray` inbound

`xray` should use a paticular `tproxy` inbound to receive traffice routed from within the container.

```jsonc
{
  "inbounds": [
    // tproxy inbound rule
    {
      "port": 12345,  // must match XRAY_INBOUND_PORT in docker-compose
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "followRedirect": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "streamSettings": {
        "sockopt": {
          "tproxy": "tproxy"
        }
      }
    },
    // other inbounds ...
  ]
}
```


### 2. Run `xray-tproxy` with docker-compose

After you've setup your config, you can run `xray-tproxy` with docker-compose.

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
      ALLOW_QUIC: "false" # it's recommended to block QUIC (UDP/443)
      XRAY_INBOUND_PORT: "12345" # must match inbound port in xray config
      LOCAL_DNS: "114.114.114.114"
      REMOTE_DNS: "8.8.8.8 1.1.1.1" # space separated dnsmasq servers
      RESERVED_IP4: "0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"
    # Using config folder in this case
    volumes:
      - ./config:/etc/xray/config
    command: ["xray", "run", "-confdir", "/etc/xray/config"]
    # You can also use `config.json` file:
    # volumes:
    #   - ./config.json:/etc/xray/config.json
    # command: ["xray", "run", "-c", "/etc/xray/config.json"]

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

and for the first time, run:

```bash
docker-compose up
```


### (Optional) Run `ash` to debug

You can run this command to run `ash` in the container.

```bash
docker exec -it tproxy ash
``` 

If you want to discover the image without the default entrypoint, you can use commands below to debug:

```bash
docker run --rm -it --entrypoint ash --cap-add=NET_ADMIN lesca/xray-tproxy:latest
```


## Environment Viariables

All the environment variables that you can set in `docker-compose.yaml` file:

* `ALLOW_QUIC`: Allow QUIC (UDP/443) traffic.
  * Default: false
* `LOCAL_DNS`: Local DNS server to be used for Xray first dialing. It has nothing to do with Xray's internal DNS.
  * Default: 114.114.114.114
* `REMOTE_DNS`: Space separated dnsmasq servers.
  * Default: `1.1.1.1 8.8.8.8`
  * You can also use something like this: `REMOTE_DNS="1.1.1.1 8.8.8.8 /qq.com/114.114.114.114"`
* `XRAY_INBOUND_PORT`: Xray works in TPROXY mode on this port. The port **must match** the inbound port of xray config.
  * Default: 12345
* `XRAY_INBOUND_MARK`: The fwmark to be used for Xray inbound packets.
  * Default: 0x1
* `ROUTE_TABLE`: Specify a route table number. All packets with fwmark 0x1 (default) will be routed to this table.
  * Default: 100
* `RESERVED_IP4`: Reversed IPv4 ranges. If destination IP is in these ranges, the packets will not be proxyed.
  * Default: "0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"
  * Removing `172.16.0.0/12` makes it possible to access remote docker network via proxy.
* `RESERVED_IP6`: Reversed IPv6 ranges. If destination IP is in these ranges, the packets will not be proxyed.
  * Default: "::1/128 fc00::/7 fe80::/10"
* `ENFORCE_LAN_SRC_IP4` and `ENFORCE_LAN_SRC_IP6`: Enforce source IP must be in LAN.
  * Default: "" (empty)
  * Example: `ENFORCE_LAN_SRC_IP4="192.168.2.0/24"`
  * This enforce `xray-tproxy` only accept traffic from within the network `192.168.2.0/24`.
  * This is useful if your box has a public IP address, and this avoids access from your WAN port neighbors.

> Note: Set these environment variables will override the default ones.

## Other topics

### About DNS

* `xray-tproxy` container uses `dnsmasq` to provide DNS service.
* All the DNS requests are re-directed to `xray` via `nftables`.
* Thus, you can safely speicify the IP address of `xray-tproxy` container on your client devices (Phone, PC, etc).