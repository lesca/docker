#!/bin/sh
# Reference documentation:
# # Reference: https://github.com/scenery/mihomo-tproxy-docker

# configs
DNS_CLIENT_SUBNET=${DNS_CLIENT_SUBNET:-"114.114.114.0/24"}
LOCAL_DNS=${LOCAL_DNS:-"114.114.114.114"}
REMOTE_DNS=${REMOTE_DNS:-"1.1.1.1 8.8.8.8"}
XRAY_INBOUND_PORT=${XRAY_INBOUND_PORT:-"12345"}
XRAY_INBOUND_MARK=${XRAY_INBOUND_MARK:-"0x1"}
ROUTE_TABLE=${ROUTE_TABLE:-"100"}
ENFORCE_LAN_SRC_IP4=${ENFORCE_LAN_SRC_IP4:-""}
ENFORCE_LAN_SRC_IP6=${ENFORCE_LAN_SRC_IP6:-""}

# reserved ip ranges
RESERVED_IP4=${RESERVED_IP4:-"0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"}
RESERVED_IP6=${RESERVED_IP6:-"::1/128 fc00::/7 fe80::/10"}
NFT_RESERVED_IP4="{ $(echo $RESERVED_IP4 | sed 's/ /, /g') }"
NFT_RESERVED_IP6="{ $(echo $RESERVED_IP6 | sed 's/ /, /g') }"

# paths
MAIN_NFT="/tmp/main.nft"
MAIN_DNS="/tmp/dns.conf"

setup_nftables() {
    nft flush ruleset
    set -e # exit on error

    # Start of main.nft
    cat > "$MAIN_NFT" <<EOF
table inet xray {

    # PRE_XRAY 链 (用于 NOTRACK) 
    # 确保在连接跟踪之前处理 (priority raw = -300)
    chain PRE_XRAY {
        type filter hook prerouting priority raw; policy accept;

        # 忽略代理的连接跟踪 (对应 iptables -t raw -A PREROUTING -m mark --mark 1 -j NOTRACK)
        meta mark == $XRAY_INBOUND_MARK notrack
    }

    # XRAY 链 (用于 TPROXY 规则)
    # priority mangle = -150
    chain XRAY {
        type filter hook prerouting priority mangle; policy accept;
EOF

    # Enforce src ip (ipv4) must be in LAN
    if [ "$ENFORCE_LAN_SRC_IP4" != "" ]; then
        cat >> "$MAIN_NFT" <<EOF
        ip saddr != $ENFORCE_LAN_SRC_IP4 return
EOF
    fi

    # Enforce src ip (ipv6) must be in LAN
    if [ "$ENFORCE_LAN_SRC_IP6" != "" ]; then
        cat >> "$MAIN_NFT" <<EOF
        ip6 saddr != $ENFORCE_LAN_SRC_IP6 return
EOF
    fi

    # Add the rest of the XRAY chain
    cat >> "$MAIN_NFT" <<EOF
        # --- 匹配/跳过规则 (RETURN) ---

        # 不处理 SSH 连接
        tcp dport 22 return

        # 不处理目标地址是局域网的流量 (私有网络)
        ip daddr $NFT_RESERVED_IP4 return
        ip6 daddr $NFT_RESERVED_IP6 return

        # --- TPROXY 转发规则 ---

        # 对 IPv4 的 TCP/UDP 流量进行 TPROXY (使用 meta nfproto)
        meta nfproto ipv4 meta l4proto { tcp, udp } tproxy ip to 127.0.0.1:12345 meta mark set $XRAY_INBOUND_MARK

        # 对 IPv6 的 TCP/UDP 流量进行 TPROXY (使用 meta nfproto)
        meta nfproto ipv6 meta l4proto { tcp, udp } tproxy ip6 to [::1]:12345 meta mark set $XRAY_INBOUND_MARK

    }

    # 4. OUTPUT 链
    # 用于将请求回流到 xray
    chain OUTPUT {
        type route hook output priority mangle; policy accept;
        # 将 dnsmasq(100:101) 的 DNS 请求回流到 xray
        meta skuid 100 meta mark set $XRAY_INBOUND_MARK
    }
}
EOF

    nft -f "$MAIN_NFT"
    rm "$MAIN_NFT"
}

# setup dns
setup_dns() {
    
    # set local dns
    echo "nameserver $LOCAL_DNS" > /etc/resolv.conf

    # show dns
    echo "Local DNS:  $LOCAL_DNS"
    echo "Remote DNS: $REMOTE_DNS"

    # dns conf
    cat >> $MAIN_DNS <<EOF
# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
no-resolv
no-poll
edns-packet-max=4096
add-subnet=$DNS_CLIENT_SUBNET
cache-size=10000
max-cache-ttl=3600
min-cache-ttl=300
EOF

    # add dns servers
    for DNS in $REMOTE_DNS; do
        echo "server=$DNS" >> "$MAIN_DNS"
    done

    # move to /etc
    mv "$MAIN_DNS" /etc/dnsmasq.conf

    # run dnsmasq
    dnsmasq --log-facility=/dev/stdout # --log-queries
}


# Add policy routing to packets marked as 1 delivered locally
if ! ip rule list | grep -q "fwmark $XRAY_INBOUND_MARK lookup $ROUTE_TABLE"; then
    ip rule add fwmark $XRAY_INBOUND_MARK lookup $ROUTE_TABLE
fi

if ! ip route show table $ROUTE_TABLE | grep -q "local default dev lo"; then
    ip route add local default dev lo table $ROUTE_TABLE
fi

# setup services
setup_nftables
setup_dns

# Run Xray
echo "WARNING: make sure the port XRAY_INBOUND_PORT=$XRAY_INBOUND_PORT matches your xray inbound config!!"
echo "Starting Xray..."
sleep 1
exec "$@"
