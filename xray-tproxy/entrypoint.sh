#!/bin/sh
# Reference documentation:
# # Reference: https://github.com/scenery/mihomo-tproxy-docker

# configs
LOCAL_DNS=${LOCAL_DNS:-"114.114.114.114"}
XRAY_INBOUND_PORT=${XRAY_INBOUND_PORT:-"12345"}
XRAY_INBOUND_MARK=${XRAY_INBOUND_MARK:-"0x1"}
ROUTE_TABLE=${ROUTE_TABLE:-"100"}
RESERVED_IPS=${RESERVED_IPS:-"0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4"}
NFT_RESERVED_IPS="{ $(echo $RESERVED_IPS | sed 's/ /, /g') }"

# paths
MAIN_NFT="/tmp/main.nft"

setup_nftables() {
    nft flush ruleset
    set -e # exit on error

    cat >> "$MAIN_NFT" <<EOF
# 1. 创建表
table ip xray_proxy {

    # 2. RAW_PREROUTING 链 (用于 NOTRACK) 
    # 确保在连接跟踪之前处理 (priority raw = -300)
    chain RAW_PREROUTING {
        type filter hook prerouting priority raw; policy accept;

        # 忽略代理的连接跟踪（对应 iptables -t raw -A PREROUTING -m mark --mark 1 -j NOTRACK）
        meta mark == $XRAY_INBOUND_MARK notrack
    }

    # 3. XRAY 链 (用于 TPROXY 规则)
    # priority mangle = -150
    chain XRAY {
        type filter hook prerouting priority mangle; policy accept;

        # --- 匹配/跳过规则 (RETURN) ---

        # 不处理 SSH 连接
        tcp dport 22 return

        # 不处理目标地址是局域网的流量 (私有网络)
        ip daddr $NFT_RESERVED_IPS return

        # --- TPROXY 转发规则 ---

        # TCP UDP 流量: 标记 1 并重定向到 XRAY_INBOUND_PORT
        ip protocol tcp tproxy to 127.0.0.1:$XRAY_INBOUND_PORT meta mark set $XRAY_INBOUND_MARK
        ip protocol udp tproxy to 127.0.0.1:$XRAY_INBOUND_PORT meta mark set $XRAY_INBOUND_MARK
    }
}
EOF

    nft -f "$MAIN_NFT"
}

# setup dns
echo "nameserver $LOCAL_DNS" > /etc/resolv.conf

# Add policy routing to packets marked as 1 delivered locally
if ! ip rule list | grep -q "fwmark $XRAY_INBOUND_MARK lookup $ROUTE_TABLE"; then
    ip rule add fwmark $XRAY_INBOUND_MARK lookup $ROUTE_TABLE
fi

if ! ip route show table $ROUTE_TABLE | grep -q "local default dev lo"; then
    ip route add local default dev lo table $ROUTE_TABLE
fi

# setup nftables
setup_nftables
rm -f "$MAIN_NFT"

# Run Xray
echo "WARNING: make sure the port XRAY_INBOUND_PORT=$XRAY_INBOUND_PORT matches your xray inbound config!!"
echo "Starting Xray..."
sleep 1
exec "$@"