#!/usr/bin/env bash
# 一键部署 SS 服务端（VPS）并启动本地客户端
set -euo pipefail

readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SERVER_SH="$DIR/server.sh"
readonly CFG=/etc/shadowsocks-rust/config.json
readonly LOCAL_ADDR="127.0.0.1"
readonly LOCAL_PORT=1080

require_ip() {
    [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid IP: $1"; exit 1; }
}

remote_ip="${1:?用法: $0 <VPS-IP>}"
require_ip "$remote_ip"

deploy_server() {
    local ip="$1"
    scp "$SERVER_SH" "root@${ip}:~/"
    ssh "root@${ip}" "bash ~/server.sh"
}

pull_config() {
    local ip="$1" out="$2"
    scp "root@${ip}:${CFG}" "$out"
}

setup_local_client() {
    local ip="$1" tmpf="$2"
    sudo mkdir -p "$(dirname "$CFG")"
    jq --arg server "$ip" \
       --arg local_addr "$LOCAL_ADDR" \
       --argjson local_port "$LOCAL_PORT" \
       '.server = $server | .local_address = $local_addr | .local_port = $local_port' \
       "$tmpf" | sudo tee "$CFG" > /dev/null
    echo "本地配置: $CFG"

    sudo systemctl stop 'shadowsocks-rust@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
    sudo pkill -x ssservice 2>/dev/null || true
    sudo systemctl enable --now shadowsocks-rust@config.service
    sleep 1
}

verify() {
    local ip="$1"
    sudo systemctl status shadowsocks-rust@config.service --no-pager -l 2>&1 | head -5
    ss -tlnp | grep ":${LOCAL_PORT} " || echo "警告: 端口 $LOCAL_PORT 未监听"
    echo ""
    echo "代理就绪: socks5h://${LOCAL_ADDR}:${LOCAL_PORT}"
    echo "测试: curl -x socks5h://${LOCAL_ADDR}:${LOCAL_PORT} https://ipinfo.io"
}

echo "=== 1. 部署服务端到 $remote_ip ==="
deploy_server "$remote_ip"

echo "=== 2. 拉取服务端配置 ==="
tmpf=$(mktemp --suffix=.json)
trap "rm -f '$tmpf'" EXIT
pull_config "$remote_ip" "$tmpf"

echo "=== 3. 配置客户端并启动 ==="
setup_local_client "$remote_ip" "$tmpf"

echo "=== 4. 验证 ==="
verify "$remote_ip"
