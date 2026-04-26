#!/bin/bash
# Shadowsocks 服务器一键配置
# 用法: $0 <密码> [端口=8388] [加密=aes-256-gcm] [配置名=config]

set -euo pipefail

PASSWORD="${1:?用法: $0 <密码> [端口] [加密方式] [配置名]}"
PORT="${2:-8388}"
METHOD="${3:-aes-256-gcm}"
NAME="${4:-config}"
CONFIG="/etc/shadowsocks-rust/${NAME}.json"
SERVICE="shadowsocks-rust-server@${NAME}"

[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) \
    || { echo "❌ 端口无效: $PORT"; exit 1; }

echo "📦 安装 shadowsocks-rust..."
sudo pacman -S shadowsocks-rust --noconfirm --needed

echo "📝 写入配置 $CONFIG..."
sudo mkdir -p /etc/shadowsocks-rust
sudo tee "$CONFIG" > /dev/null <<EOF
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "$METHOD",
    "timeout": 300,
    "fast_open": false,
    "mode": "tcp_and_udp"
}
EOF

echo "🚀 启动服务..."
sudo systemctl disable --now "shadowsocks-server@${NAME}" 2>/dev/null || true
sudo systemctl enable --now "$SERVICE"

echo "🔥 开放防火墙端口 $PORT..."
sudo iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
sudo iptables -A INPUT -p udp --dport "$PORT" -j ACCEPT
sudo mkdir -p /etc/iptables
sudo iptables-save | sudo tee /etc/iptables/iptables.rules > /dev/null

echo "✅ 完成！服务状态:"
sudo systemctl status "$SERVICE" --no-pager

PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo '<服务器IP>')
echo -e "\n🔗 连接信息: IP=$PUBLIC_IP  端口=$PORT  密码=$PASSWORD  加密=$METHOD"

echo -e "\n📋 配置文件 $CONFIG:"
sudo cat "$CONFIG"
