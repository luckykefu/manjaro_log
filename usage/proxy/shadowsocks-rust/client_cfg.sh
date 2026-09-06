#!/usr/bin/env bash
# client_cfg.sh — 本地：从 VPS 拉取配置并启动 ss 客户端
set -euo pipefail

require_ip() { local ip=$1; [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid IP: $ip"; exit 1; } }
open_port() {
    local port="$1" proto="${2:-tcp}"
    if command -v firewall-cmd &>/dev/null; then
        sudo firewall-cmd --add-port="${port}/${proto}" --permanent 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
    elif command -v ufw &>/dev/null; then
        sudo ufw allow "${port}/${proto}" 2>/dev/null || true
    elif command -v iptables &>/dev/null; then
        sudo iptables -C INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null ||
            sudo iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
    else
        echo "未检测到防火墙工具，跳过"
    fi
}

readonly LOCAL_ADDR="0.0.0.0"
readonly LOCAL_PORT=1080
readonly SS_CFG=/etc/shadowsocks-rust/config.json

fetch_and_patch_config() {
    local remote_ip="$1"
    local tmpf
    tmpf=$(mktemp --suffix=.json)
    trap "rm -f '$tmpf'" EXIT

    scp "root@${remote_ip}:${SS_CFG}" "$tmpf"

    sudo mkdir -p "$(dirname "$SS_CFG")"
    jq --arg  server     "$remote_ip"   \
       --arg  local_addr "$LOCAL_ADDR"  \
       --argjson local_port "$LOCAL_PORT" \
       '.server = $server | .local_address = $local_addr | .local_port = $local_port' \
       "$tmpf" | sudo tee "$SS_CFG" > /dev/null
    echo "客户端配置写入 $SS_CFG"
}

setup_service() {
    echo "重启 shadowsocks-rust 客户端"
    sudo systemctl stop    'shadowsocks-rust@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
    sudo pkill -x ssservice 2>/dev/null || true
    sudo systemctl enable --now shadowsocks-rust@config.service
}

verify() {
    echo "验证"
    sudo systemctl status shadowsocks-rust@config.service --no-pager -l
    ss -tlnp | grep ":${LOCAL_PORT} " || echo "端口 $LOCAL_PORT 未监听"
    echo "客户端就绪 ✓"
}

remote_ip="${1:?用法: $0 <VPS-IP>}"
require_ip "$remote_ip"

sudo pacman -S --needed --noconfirm shadowsocks-rust jq
fetch_and_patch_config "$remote_ip"
setup_service
# open_port "$LOCAL_PORT" tcp
verify
