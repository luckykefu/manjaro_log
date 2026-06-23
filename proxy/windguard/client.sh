#!/usr/bin/env bash
# WG 客户端配置 — 生成密钥、写入配置、启动服务
set -euo pipefail

readonly WG_DIR=/etc/wireguard
readonly WG_IFACE=wg0
readonly WG_NET=10.10.0.0/24
readonly CLIENT_IP=10.10.0.2/24

server_pub="${1:?用法: $0 <server-pubkey> <server-endpoint>}"
endpoint="${2:-45.32.60.113:51820}"

if ! command -v wg &>/dev/null; then
    sudo pacman -S wireguard-tools --noconfirm
fi

sudo mkdir -p "$WG_DIR"

if [[ ! -f $WG_DIR/client.key ]]; then
    wg genkey | sudo tee "$WG_DIR/client.key" | wg pubkey | sudo tee "$WG_DIR/client.pub" > /dev/null
    sudo chmod 600 "$WG_DIR/client.key"
fi

priv=$(sudo cat "$WG_DIR/client.key")

sudo tee "$WG_DIR/$WG_IFACE.conf" > /dev/null << EOF
[Interface]
Address = $CLIENT_IP
PrivateKey = $priv

[Peer]
PublicKey = $server_pub
Endpoint = $endpoint
AllowedIPs = $WG_NET
PersistentKeepalive = 25
EOF

sudo chmod 600 "$WG_DIR/$WG_IFACE.conf"
sudo systemctl enable --now wg-quick@"$WG_IFACE"

echo "=== 客户端公钥 ==="
sudo cat "$WG_DIR/client.pub"
