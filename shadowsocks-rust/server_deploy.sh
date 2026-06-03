#!/usr/bin/env bash
# server_deploy.sh — VPS 端：安装 shadowsocks-rust 并生成配置
set -euo pipefail

readonly SS_PORT=8388
readonly SS_CFG=/etc/shadowsocks-rust/config.json
readonly SS_METHOD="2022-blake3-aes-256-gcm"

gen_config() {
    echo "生成服务端配置"
    local pass
    pass=$(ssservice genkey -m "$SS_METHOD")
    sudo mkdir -p "$(dirname "$SS_CFG")"
    sudo tee "$SS_CFG" > /dev/null << EOF
{
    "server":      "0.0.0.0",
    "server_port": ${SS_PORT},
    "password":    "${pass}",
    "method":      "${SS_METHOD}",
    "mode":        "tcp_and_udp"
}
EOF
    echo "配置写入 $SS_CFG"
    cat "$SS_CFG"
}

setup_service() {
    echo "配置 systemd 服务"
    # 幂等：先停掉所有旧实例
    sudo systemctl stop    'shadowsocks-rust-server@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust-server@*' 2>/dev/null || true
    sudo systemctl enable --now shadowsocks-rust-server@config.service
}
open_port() {
    local port="$1" proto="${2:-tcp}"
    echo "开放端口 ${port}/${proto}"
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
verify() {
    echo "验证监听端口"
    ss -tlnp | grep ":${SS_PORT} " || echo "端口 $SS_PORT 未监听，请检查日志"
    echo "服务端就绪 ✓"
}

sudo pacman -S --needed --noconfirm shadowsocks-rust
gen_config
setup_service
open_port "$SS_PORT" tcp
open_port "$SS_PORT" udp
verify
