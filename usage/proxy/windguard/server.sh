#!/usr/bin/env bash
# WireGuard 服务端 (在 VPS 上执行)
set -euo pipefail

readonly WG_DIR=/etc/wireguard
readonly WG_IFACE=wg0
readonly WG_NET=10.10.0.0/24
readonly SERVER_IP=10.10.0.1/24
readonly WG_PORT=51820

pacman -S wireguard-tools --noconfirm
mkdir -p "$WG_DIR"

wg genkey | tee "$WG_DIR/server.key" | wg pubkey > "$WG_DIR/server.pub"
chmod 600 "$WG_DIR/server.key"

IFACE=$(ip -o link show | grep -v 'lo\|wg0' | head -1 | awk -F': ' '{print $2}')

cat > "$WG_DIR/$WG_IFACE.conf" << EOF
[Interface]
Address = $SERVER_IP
ListenPort = $WG_PORT
PrivateKey = $(cat "$WG_DIR/server.key")
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i $WG_IFACE -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -s $WG_NET -o $IFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_IFACE -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -s $WG_NET -o $IFACE -j MASQUERADE
EOF

if command -v ufw &>/dev/null; then
    ufw allow "$WG_PORT"/udp
fi

systemctl enable --now wg-quick@"$WG_IFACE"

echo "=== 服务端公钥 ==="
cat "$WG_DIR/server.pub"
