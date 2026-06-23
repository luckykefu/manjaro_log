#!/usr/bin/env bash
# 一键部署 SS 服务端（VPS）并启动本地客户端
set -euo pipefail

readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SERVER_SH="$DIR/server.sh"
readonly LOCAL_CFG=/etc/shadowsocks-rust/config.json
readonly LOCAL_ADDR="127.0.0.1"
readonly LOCAL_PORT=1080

require_ip() {
    [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid IP: $1"; exit 1; }
}

remote_ip="${1:?用法: $0 <VPS-IP>}"
require_ip "$remote_ip"

echo "=== 1. 部署服务端到 $remote_ip ==="
scp "$SERVER_SH" "root@${remote_ip}:~/"
ssh "root@${remote_ip}" "bash ~/server.sh"

echo "=== 2. 拉取服务端配置 ==="
tmpf=$(mktemp --suffix=.json)
trap "rm -f '$tmpf'" EXIT

scp "root@${remote_ip}:${LOCAL_CFG}" "$tmpf"

echo "=== 3. 生成本地客户端配置 ==="
sudo mkdir -p "$(dirname "$LOCAL_CFG")"
jq --arg server "$remote_ip" \
   --arg local_addr "$LOCAL_ADDR" \
   --argjson local_port "$LOCAL_PORT" \
   '.server = $server | .local_address = $local_addr | .local_port = $local_port' \
   "$tmpf" | sudo tee "$LOCAL_CFG" > /dev/null
echo "本地配置: $LOCAL_CFG"

echo "=== 4. 启动本地客户端 ==="
sudo systemctl stop 'shadowsocks-rust@*' 2>/dev/null || true
sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
sudo pkill -x ssservice 2>/dev/null || true
sudo systemctl enable --now shadowsocks-rust@config.service
sleep 1

echo "=== 5. 验证 ==="
sudo systemctl status shadowsocks-rust@config.service --no-pager -l 2>&1 | head -5
ss -tlnp | grep ":${LOCAL_PORT} " || echo "警告: 端口 $LOCAL_PORT 未监听"
echo ""

colab_ip=$remote_ip
echo "代理就绪: socks5h://${LOCAL_ADDR}:${LOCAL_PORT}"
echo "测试: curl -x socks5h://${LOCAL_ADDR}:${LOCAL_PORT} https://ipinfo.io"
