#!/usr/bin/env bash
# SS 配置转 Clash yaml 工具
# 用法: clash.sh <ip> [remote_cfg=/etc/shadowsocks-rust/config.json] [节点名] [输出文件]

set -euo pipefail

REMOTE_CFG="${2:-/etc/shadowsocks-rust/config.json}"
NODE="${3:-SS节点}"
OUT="${4:-/tmp/clash_config.yaml}"
IP="$1"

[[ -z "$IP" ]] && { echo "用法: $0 <ip> [remote_cfg] [节点名] [输出文件]"; exit 1; }

tmp=$(mktemp /tmp/ss_config.XXXXXX.json)
trap 'rm -f "$tmp"' EXIT

scp "root@${IP}:${REMOTE_CFG}" "$tmp"

server_port=$(jq -r '.server_port' "$tmp")
method=$(jq -r '.method' "$tmp")
password=$(jq -r '.password' "$tmp")

mkdir -p "$(dirname "$OUT")"

yq -n -y \
  --arg ip "$IP" \
  --arg node "$NODE" \
  --arg port "$server_port" \
  --arg cipher "$method" \
  --arg password "$password" \
  '{
    "mixed-port": 7897,
    "allow-lan": true,
    "mode": "rule",
    "log-level": "info",
    "external-controller": "127.0.0.1:9090",
    "proxies": [
      {
        "name": $node,
        "type": "ss",
        "server": $ip,
        "port": ($port | tonumber),
        "cipher": $cipher,
        "password": $password,
        "udp": true
      }
    ],
    "proxy-groups": [
      {
        "name": "Proxy",
        "type": "url-test",
        "proxies": [$node],
        "url": "http://cp.cloudflare.com/generate_204",
        "interval": 300
      }
    ],
    "rules": [
      "DOMAIN-SUFFIX,local,DIRECT",
      "IP-CIDR,127.0.0.0/8,DIRECT",
      "IP-CIDR,192.168.0.0/16,DIRECT",
      "DOMAIN-SUFFIX,cn,DIRECT",
      "DOMAIN-KEYWORD,baidu,DIRECT",
      "GEOIP,CN,DIRECT",
      "MATCH,Proxy"
    ]
  }' > "$OUT"
echo "✅ 已生成: $OUT"
