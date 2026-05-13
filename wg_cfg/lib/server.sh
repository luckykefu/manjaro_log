#!/usr/bin/env bash

server_install_and_config() {
    ensure_cmd ssh openssh
    header "1/4 配置公网服务器: $IP"

    ssh $SSH_OPTS "root@$IP" bash -s "$WG_PORT" << 'SRVEOF'
WG_PORT=$1
WG_DIR=/etc/wireguard
mkdir -p "$WG_DIR"

pacman -Sy --noconfirm wireguard-tools
wg genkey | tee "$WG_DIR/privatekey" | wg pubkey > "$WG_DIR/publickey"
chmod 600 "$WG_DIR/privatekey"
SERVER_PRIV=$(cat "$WG_DIR/privatekey")
SERVER_PUB=$(cat "$WG_DIR/publickey")

IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')

cat > "$WG_DIR/wg0.conf" << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = ${SERVER_PRIV}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${IFACE} -j MASQUERADE

[Peer]
PublicKey = <LOCAL_PUB>
AllowedIPs = 10.0.0.2/32
EOF

chmod 600 "$WG_DIR/wg0.conf"
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
systemctl enable wg-quick@wg0 2>/dev/null || true
echo "SERVER_PUB_KEY=${SERVER_PUB}"
SRVEOF
}

server_fetch_pubkey() {
    ensure_cmd ssh openssh
    ssh $SSH_OPTS "root@$IP" "cat /etc/wireguard/publickey"
}

server_exchange_key() {
    ensure_cmd ssh openssh
    local local_pub="$1"
    ssh $SSH_OPTS "root@$IP" "sed -i 's|<LOCAL_PUB>|$local_pub|' /etc/wireguard/wg0.conf"
}

server_start() {
    ensure_cmd ssh openssh
    ssh $SSH_OPTS "root@$IP" "systemctl restart wg-quick@wg0"
}
