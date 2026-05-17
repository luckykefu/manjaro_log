#!/usr/bin/env bash
remote_ip="${1:-202.182.112.91}"
local_port="${2:-1080}"

sudo pacman -S --needed --noconfirm shadowsocks-rust

tmpf=$(mktemp)
trap 'rm -f "$tmpf"' EXIT

echo "==> 从 ${remote_ip} 拉取服务端配置..."
scp "root@${remote_ip}:/etc/shadowsocks-rust/config.json" "$tmpf"

echo "==> 生成客户端配置..."
sudo mkdir -p /etc/shadowsocks-rust
jq --arg server "$remote_ip" \
   --arg local_addr "127.0.0.1" \
   --argjson local_port "$local_port" \
   '.server = $server | . + {local_address: $local_addr, local_port: $local_port}' \
   "$tmpf" | sudo tee /etc/shadowsocks-rust/config.json > /dev/null

echo "==> 停掉已有客户端实例..."
sudo systemctl stop    'shadowsocks-rust@*' 2>/dev/null || true
sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
sudo pkill -x ssservice 2>/dev/null || true
echo "==> 启动 shadowsocks-rust 客户端..."
sudo systemctl enable --now shadowsocks-rust@config.service

echo "==> 验证..."
sudo systemctl status shadowsocks-rust@config.service --no-pager -l
sudo ss -tlnp | grep ":${local_port} " || echo "⚠️ 端口 ${local_port} 未监听，请检查配置"
