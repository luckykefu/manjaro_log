#!/usr/bin/env bash
set -euo pipefail
# ============================================================
#  WireGuard 客户端 + 服务端一键部署脚本（分步骤输出）
#  用法: bash deploy-wg.sh
# ============================================================
# ---------- 配置区 ----------
IP=64.176.225.208
SSH_PORT=22
WG_PORT=51820
WG_DIR=/etc/wireguard
SSH_OPTS="-p $SSH_PORT -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"
# ---------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
step()  { echo -e "\n${CYAN}[STEP $1/$TOTAL]${NC} $2"; }
info()  { echo -e "  ${GREEN}->${NC} $1"; }
warn()  { echo -e "  ${YELLOW}WARN:${NC} $1"; }
err()   { echo -e "  ${RED}ERROR:${NC} $1"; }
detect_firewall() {
    if command -v firewall-cmd &>/dev/null; then
        echo "firewalld"
    elif command -v ufw &>/dev/null; then
        echo "ufw"
    elif command -v nft &>/dev/null; then
        echo "nftables"
    else
        echo "iptables"
    fi
}
open_firewall_port() {
    local host=$1 port=$2 proto=$3
    case "$FW" in
        firewalld)
            ssh "$host" "firewall-cmd --add-port=${port}/${proto} --permanent && firewall-cmd --reload"
            ;;
        ufw)
            ssh "$host" "ufw allow ${port}/${proto}"
            ;;
        nftables)
            warn "nftables 自动放行未实现，请手动添加规则"
            ;;
        iptables)
            ssh "$host" "iptables -A INPUT -p ${proto} --dport ${port} -j ACCEPT"
            ;;
    esac
}
# ============================================================
#  步骤计数（方便调整总数）
# ============================================================
TOTAL=14
# ============================================================
#  1. 检测客户端依赖
# ============================================================
step 1 "检测客户端依赖"
if ! command -v wg &>/dev/null; then
    info "安装 wireguard-tools"
    sudo pacman -S --noconfirm --needed wireguard-tools openresolv
else
    info "wireguard-tools 已安装"
fi
# ============================================================
#  2. 检测服务端防火墙类型
# ============================================================
step 2 "检测服务端防火墙类型"
FW=$(ssh root@$IP "$(typeset -f detect_firewall); detect_firewall")
info "服务端防火墙: $FW"
# ============================================================
#  3. 服务端安装 WireGuard
# ============================================================
step 3 "服务端安装 wireguard-tools"
ssh root@$IP "sudo pacman -S --noconfirm --needed wireguard-tools"
info "完成"
# ============================================================
#  4. 服务端放行防火墙（UDP）
# ============================================================
step 4 "服务端放行 UDP $WG_PORT 端口"
case "$FW" in
    firewalld)
        ssh root@$IP "firewall-cmd --add-port=${WG_PORT}/udp --permanent && firewall-cmd --reload"
        ;;
    ufw)
        ssh root@$IP "ufw allow ${WG_PORT}/udp"
        ;;
    nftables)
        warn "nftables 请手动放行 udp ${WG_PORT}"
        ;;
    iptables)
        ssh root@$IP "iptables -A INPUT -p udp --dport ${WG_PORT} -j ACCEPT"
        ;;
esac
info "完成"
# ============================================================
#  5. 生成服务端密钥对
# ============================================================
step 5 "生成服务端 WireGuard 密钥对"
ssh root@$IP "sudo mkdir -p $WG_DIR && wg genkey | sudo tee $WG_DIR/privatekey | wg pubkey | sudo tee $WG_DIR/publickey > /dev/null && sudo chmod 600 $WG_DIR/privatekey"
SERVER_PRIV=$(ssh root@$IP "sudo cat $WG_DIR/privatekey")
SERVER_PUB=$(ssh root@$IP "sudo cat $WG_DIR/publickey")
info "服务端公钥: $SERVER_PUB"
# ============================================================
#  6. 获取服务端外网网卡名（用于 NAT 伪装）
# ============================================================
step 6 "获取服务端默认路由网卡"
IFACE=$(ssh root@$IP "ip route get 1.1.1.1" | awk '{print $5; exit}')
info "网卡: $IFACE"
# ============================================================
#  7. 生成客户端密钥对
# ============================================================
step 7 "生成客户端 WireGuard 密钥对"
sudo mkdir -p "$WG_DIR"
wg genkey | sudo tee "$WG_DIR/privatekey" | wg pubkey | sudo tee "$WG_DIR/publickey" > /dev/null
sudo chmod 600 "$WG_DIR/privatekey"
LOCAL_PRIV=$(sudo cat "$WG_DIR/privatekey")
LOCAL_PUB=$(sudo cat "$WG_DIR/publickey")
info "客户端公钥: $LOCAL_PUB"
# ============================================================
#  8. 写入客户端 wg0.conf
# ============================================================
step 8 "写入客户端配置文件 $WG_DIR/wg0.conf"
sudo tee "$WG_DIR/wg0.conf" > /dev/null << EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = ${LOCAL_PRIV}
DNS = 1.1.1.1
[Peer]
PublicKey = ${SERVER_PUB}
Endpoint = ${IP}:${WG_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
sudo chmod 600 "$WG_DIR/wg0.conf"
info "完成"
# ============================================================
#  9. 写入服务端 wg0.conf
# ============================================================
step 9 "写入服务端配置文件 $WG_DIR/wg0.conf"
ssh root@$IP "sudo tee $WG_DIR/wg0.conf" > /dev/null << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = $WG_PORT
PrivateKey = ${SERVER_PRIV}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${IFACE} -j MASQUERADE
[Peer]
PublicKey = ${LOCAL_PUB}
AllowedIPs = 10.0.0.2/32
EOF
ssh root@$IP "sudo chmod 600 $WG_DIR/wg0.conf"
info "完成"
# ============================================================
#  10. 服务端开启 IP 转发
# ============================================================
step 10 "服务端开启 IP 转发"
if ssh root@$IP "grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null"; then
    info "IP 转发已配置，跳过"
else
    ssh root@$IP "echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf > /dev/null && sudo sysctl -p"
    info "完成"
fi
# ============================================================
#  11. 服务端启用并启动 WireGuard
# ============================================================
step 11 "服务端启用并启动 wg-quick@wg0"
ssh root@$IP "sudo systemctl enable wg-quick@wg0 && sudo systemctl restart wg-quick@wg0"
info "完成"
# ============================================================
#  12. 保存服务端公钥到本地
# ============================================================
step 12 "保存服务端公钥到本地"
echo "$SERVER_PUB" | sudo tee /etc/wireguard/server_public_key > /dev/null
info "已保存至 /etc/wireguard/server_public_key"
# ============================================================
#  13. 客户端启用并启动 WireGuard
# ============================================================
step 13 "客户端启用并启动 wg-quick@wg0"
sudo pacman -S --noconfirm --needed openresolv
sudo sed -i '/^DNS = /d' /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0
sudo systemctl restart wg-quick@wg0
info "完成"
# ============================================================
#  14. 连通性测试
# ============================================================
step 14 "连通性测试 — ping 服务端 WireGuard IP (10.0.0.1)"
if ping -c 3 -W 3 10.0.0.1 &>/dev/null; then
    echo -e "  ${GREEN}✓ 连通成功！10.0.0.1 可达${NC}"
else
    echo -e "  ${RED}✗ 连通失败，请检查：${NC}"
    echo "    1) 服务端防火墙是否放行 UDP $WG_PORT"
    echo "    2) iptables PostUp 规则是否生效"
    echo "    3) 服务端 wg0 状态: ssh root@$IP 'sudo wg show'"
    exit 1
fi
# ============================================================
#  完成
# ============================================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  WireGuard 部署成功！${NC}"
echo -e "${GREEN}  服务端公钥: $SERVER_PUB${NC}"
echo -e "${GREEN}  客户端 IP : 10.0.0.2${NC}"
echo -e "${GREEN}========================================${NC}"

ssh root@$IP "sudo pacman -S --noconfirm --needed sshpass"
ssh root@$IP 'ssh-keygen -t ed25519 -C "" -f "$HOME/.ssh/id_ed25519" -N ""'
REMOTE_SSHKEYS=$(ssh root@$IP 'cat ~/.ssh/id_ed25519.pub')
echo "$REMOTE_SSHKEYS" >> ~/.ssh/authorized_keys
