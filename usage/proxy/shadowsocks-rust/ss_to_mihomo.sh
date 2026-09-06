#!/usr/bin/env bash
set -euo pipefail

readonly REMOTE_IP="${1:?用法: $0 <VPS-IP>}"
readonly SS_REMOTE_CFG="/etc/shadowsocks-rust/config.json"
readonly SS_LOCAL_TMP=$(mktemp --suffix=.json)
readonly DIR="$(cd "$(dirname "$0")" && pwd)"
readonly MIHOMO_DIR="$(cd "$DIR/../mihomo" && pwd)"
readonly TEMPLATE="$MIHOMO_DIR/config copy.yaml"
readonly OUTPUT="$MIHOMO_DIR/config.yaml"
readonly YQ="yq -yi"

trap "rm -f '$SS_LOCAL_TMP'" EXIT

sudo pacman -S --needed --noconfirm jq yq &>/dev/null

# 1. 从 VPS 拉取 SS 配置
echo "拉取 $REMOTE_IP:$SS_REMOTE_CFG ..."
scp "root@${REMOTE_IP}:${SS_REMOTE_CFG}" "$SS_LOCAL_TMP"

# 2. 修正 server 地址（VPS 配置里为 0.0.0.0）
jq --arg ip "$REMOTE_IP" '.server = $ip' "$SS_LOCAL_TMP" > "${SS_LOCAL_TMP}.fix"
mv "${SS_LOCAL_TMP}.fix" "$SS_LOCAL_TMP"

# 3. 解析 SS 配置
SERVER=$(jq -r '.server' "$SS_LOCAL_TMP")
PORT=$(jq -r '.server_port' "$SS_LOCAL_TMP")
METHOD=$(jq -r '.method' "$SS_LOCAL_TMP")
PASSWORD=$(jq -r '.password' "$SS_LOCAL_TMP")
NAME="ss-$SERVER"

echo "  节点: $SERVER:$PORT  $METHOD"

# 4. 基于模板生成纯净配置
[[ -f "$TEMPLATE" ]] || { echo "错误: 模板不存在 $TEMPLATE" >&2; exit 1; }

cp "$TEMPLATE" "$OUTPUT"

$YQ '.proxies = []' "$OUTPUT"
$YQ '.["proxy-groups"] = []' "$OUTPUT"
$YQ '.rules = []' "$OUTPUT"

$YQ '.proxies += [{"name": "'"$NAME"'", "type": "ss", "server": "'"$SERVER"'", "port": '"$PORT"', "cipher": "'"$METHOD"'", "password": "'"$PASSWORD"'", "udp": true}]' "$OUTPUT"

$YQ '.["proxy-groups"] += [{"name": "Proxy", "type": "select", "proxies": ["'"$NAME"'", "DIRECT"]}]' "$OUTPUT"
$YQ '.["proxy-groups"] += [{"name": "Auto", "type": "url-test", "proxies": ["'"$NAME"'"], "url": "https://www.gstatic.com/generate_204", "interval": 300}]' "$OUTPUT"

$YQ '.rules = ["DOMAIN-SUFFIX,local,DIRECT", "DOMAIN-SUFFIX,localhost,DIRECT", "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve", "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve", "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve", "GEOIP,CN,DIRECT", "MATCH,Proxy"]' "$OUTPUT"

echo "✓ 纯净配置已写入 $OUTPUT"
echo "运行: bash $MIHOMO_DIR/start.sh --tun"
