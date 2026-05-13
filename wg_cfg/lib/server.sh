#!/usr/bin/env bash
set -euo pipefail

server_install_and_config() {
    header "1/4 配置公网服务器: $IP"

    ssh $SSH_OPTS "root@$IP" bash -s "$WG_PORT" <<'SRVEOF'
set -euo pipefail
WG_PORT=$1
WG_DIR=/etc/wireguard
mkdir -p "$WG_DIR"

install_wg() {
    command -v wg &>/dev/null && return
    if command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm wireguard-tools
    elif command -v apt &>/dev/null; then
        apt update -y && apt install -y wireguard
    elif command -v dnf &>/dev/null; then
        dnf install -y wireguard-tools
    else
        echo "ERROR: No known package manager" >&2
        exit 1
    fi
}
install_wg

[[ -s "$WG_DIR/privatekey" ]] || wg genkey | tee "$WG_DIR/privatekey" | wg pubkey > "$WG_DIR/publickey"
chmod 600 "$WG_DIR/privatekey"
SERVER_PRIV=$(cat "$WG_DIR/privatekey")
SERVER_PUB=$(cat "$WG_DIR/publickey")

IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')

cat > "$WG_DIR/wg0.conf" <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = ${SERVER_PRIV}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${IFACE} -j MASQUERADE

[Peer]
# 本地机器 (自动填入)
PublicKey = <LOCAL_PUB>
AllowedIPs = 10.0.0.2/32
EOF

chmod 600 "$WG_DIR/wg0.conf"

grep -q 'net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null || {
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf && sysctl -p
}
grep -q 'net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf 2>/dev/null || {
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf && sysctl -p
}

command -v ufw &>/dev/null && ufw allow ${WG_PORT}/udp && ufw reload || true
command -v firewall-cmd &>/dev/null && firewall-cmd --add-port=${WG_PORT}/udp --permanent && firewall-cmd --reload || true

systemctl enable wg-quick@wg0 2>/dev/null || true

echo "SERVER_PUB_KEY=${SERVER_PUB}"
SRVEOF
}

server_fetch_pubkey() {
    ssh $SSH_OPTS "root@$IP" "cat /etc/wireguard/publickey"
}

server_exchange_key() {
    local local_pub="$1"
    ssh $SSH_OPTS "root@$IP" "sed -i 's|<LOCAL_PUB>|$local_pub|' /etc/wireguard/wg0.conf"
    info "本地公钥已写入服务器配置"
}

server_start() {
    info "启动服务器 WireGuard..."
    ssh $SSH_OPTS "root@$IP" "systemctl restart wg-quick@wg0 && systemctl status wg-quick@wg0 --no-pager | head -5"
}
