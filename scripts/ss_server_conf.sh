#!/bin/bash
# Shadowsocks 服务器一键配置
# 用法: setup_ss_server <password> [port=8388]

set -euo pipefail

setup_ss_server() {
    # $1: password (可选, 默认自动生成), $2: port (可选, 默认8388)
    local PASSWORD="${1:-$(openssl rand -base64 32)}"
    local PORT="${2:-8388}"
    local NAME=config
    local CONFIG="/etc/shadowsocks-rust/${NAME}.json"
    local SERVICE="shadowsocks-rust-server@${NAME}"

    echo "📦 安装 shadowsocks-rust..."
    sudo pacman -S shadowsocks-rust --noconfirm --needed

    echo "📝 写入配置 $CONFIG..."
    sudo mkdir -p /etc/shadowsocks-rust
    sudo tee "$CONFIG" > /dev/null <<EOF
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "2022-blake3-aes-256-gcm",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF

    echo "🚀 启动服务..."
    sudo systemctl disable --now "shadowsocks-server@${NAME}" 2>/dev/null || true
    sudo systemctl enable --now "$SERVICE"

    echo "🔥 开放防火墙端口 $PORT..."
    if command -v ufw &>/dev/null && ufw status | grep -q 'active'; then
        sudo ufw allow "$PORT/tcp"
        sudo ufw allow "$PORT/udp"
    else
        sudo iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
        sudo iptables -A INPUT -p udp --dport "$PORT" -j ACCEPT
    fi

    echo "✅ 完成！服务状态:"
    sudo systemctl status "$SERVICE" --no-pager

    echo -e "\n📋 配置文件 $CONFIG:"
    sudo cat "$CONFIG"
    echo -e "\n🔑 密码: $PASSWORD"
}

setup_ss_server "$@"
