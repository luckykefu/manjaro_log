#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# WireGuard 一键配置脚本 (从本地执行)
# 用法: wg_cfg.sh <server-ip> [ssh-port]
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[x]${NC} $1"; }
header(){ echo -e "\n${CYAN}=== $1 ===${NC}"; }

wg_cfg() {
    local IP="${1:-}"
    local SSH_PORT="${2:-22}"

    [[ -z "$IP" ]] && { err "用法: wg_cfg.sh <server-ip> [ssh-port]"; exit 1; }
    local SSH_OPTS="-p $SSH_PORT -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -i /home/lkf/.ssh/id_ed25519"

    local WG_PORT=51820
    local WG_NET="10.0.0.0/24"
    local BASE_NET="10.0.0"

    header "WireGuard 一键隧道搭建 - 目标服务器 $IP"

    # ----- 1. 配置公网服务器 -----
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

command -v ufw &>/dev/null && ufw allow ${WG_PORT}/udp && ufw reload || true
command -v firewall-cmd &>/dev/null && firewall-cmd --add-port=${WG_PORT}/udp --permanent && firewall-cmd --reload || true

systemctl enable wg-quick@wg0 2>/dev/null || true

echo "SERVER_PUB_KEY=${SERVER_PUB}"
SRVEOF

    # 获取服务器公钥
    local SERVER_OUTPUT
    SERVER_OUTPUT=$(ssh $SSH_OPTS "root@$IP" bash -s <<'SRVEOF'
cat /etc/wireguard/publickey
SRVEOF
)
    local SERVER_PUB_KEY="$SERVER_OUTPUT"
    info "服务器公钥: $SERVER_PUB_KEY"

    # ----- 2. 配置本地机器 -----
    header "2/4 配置本地机器"
    install_wg() {
        command -v wg &>/dev/null && return
        warn "安装 WireGuard..."
        if command -v pacman &>/dev/null; then
            pacman -Sy --noconfirm wireguard-tools
        elif command -v apt &>/dev/null; then
            apt update -y && apt install -y wireguard
        elif command -v dnf &>/dev/null; then
            dnf install -y wireguard-tools
        elif command -v brew &>/dev/null; then
            brew install wireguard-tools
        else
            err "请手动安装 WireGuard"
        fi
    }
    install_wg

    local WG_DIR=/etc/wireguard
    mkdir -p "$WG_DIR"
    [[ -s "$WG_DIR/privatekey" ]] || wg genkey | tee "$WG_DIR/privatekey" | wg pubkey > "$WG_DIR/publickey"
    chmod 600 "$WG_DIR/privatekey"
    local LOCAL_PRIV=$(cat "$WG_DIR/privatekey")
    local LOCAL_PUB=$(cat "$WG_DIR/publickey")
    info "本地公钥: $LOCAL_PUB"

    cat > "$WG_DIR/wg0.conf" <<EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = ${LOCAL_PRIV}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
Endpoint = ${IP}:${WG_PORT}
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF
    chmod 600 "$WG_DIR/wg0.conf"

    # ----- 3. 将本地公钥写入服务器 -----
    header "3/4 交换密钥并启动"
    ssh $SSH_OPTS "root@$IP" "sed -i 's|<LOCAL_PUB>|$LOCAL_PUB|' /etc/wireguard/wg0.conf"
    info "本地公钥已写入服务器配置"

    # ----- 4. 启动服务 -----
    info "启动服务器 WireGuard..."
    ssh $SSH_OPTS "root@$IP" "systemctl restart wg-quick@wg0 && systemctl status wg-quick@wg0 --no-pager | head -5"

    info "启动本地 WireGuard..."
    systemctl enable wg-quick@wg0 2>/dev/null || true
    systemctl restart wg-quick@wg0 2>/dev/null && info "WG 已启动 (systemd)" || {
        warn "systemd 不可用，尝试 wg-quick up..."
        wg-quick up wg0 2>/dev/null || warn "请手动启动: wg-quick up wg0"
    }

    # 连通性检查
    header "验证"
    sleep 2
    ping -c 2 -W 3 10.0.0.1 &>/dev/null && info "本地 -> 服务器: 连通 ✓" || warn "本地 -> 服务器: 未连通，请检查防火墙 (需开放 $WG_PORT/udp)"

    header "=== 配置完成 ==="
    echo ""
    echo "  服务器公钥: $SERVER_PUB_KEY"
    echo "  本地公钥:   $LOCAL_PUB"
    echo ""
    echo "  ┌──────────┐     ┌──────────┐     ┌──────────┐"
    echo "  │  本地(L)  │────│ 服务器(S) │────│  远程(R)  │"
    echo "  │ 10.0.0.2 │    │ 10.0.0.1 │    │ 10.0.0.3 │"
    echo "  └──────────┘     └──────────┘     └──────────┘"
    echo ""
    echo "【远程机器配置步骤】"
    echo "  在远程机器上运行:"
    echo "  sudo pacman -Sy wireguard-tools"
    echo "  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey"
    echo "  LOCAL_PRIV=\$(cat /etc/wireguard/privatekey)"
    echo "  REMOTE_PUB=\$(cat /etc/wireguard/publickey)"
    echo ""
    echo "  cat > /etc/wireguard/wg0.conf << EOF"
    echo "  [Interface]"
    echo "  Address = 10.0.0.3/24"
    echo "  PrivateKey = \${LOCAL_PRIV}"
    echo ""
    echo "  [Peer]"
    echo "  PublicKey = ${SERVER_PUB_KEY}"
    echo "  Endpoint = ${IP}:${WG_PORT}"
    echo "  AllowedIPs = 10.0.0.0/24"
    echo "  PersistentKeepalive = 25"
    echo "  EOF"
    echo ""
    echo "  然后执行: wg-quick up wg0"
    echo ""
    echo "  在服务器上添加远程 peer:"
    echo "  ssh root@${IP} \"tee -a /etc/wireguard/wg0.conf << 'PEER'\""
    echo "  [Peer]"
    echo "  PublicKey = <远程公钥>"
    echo "  AllowedIPs = 10.0.0.3/32"
    echo "  PEER"
    echo ""
    echo "  连接本地: ssh user@10.0.0.2"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && wg_cfg "$@"