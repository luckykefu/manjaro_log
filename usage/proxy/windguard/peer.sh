#!/usr/bin/env bash
# 添加客户端 Peer 到 VPS 服务端
set -euo pipefail

vps_ip="${1:?用法: $0 <vps-ip> <client-pubkey>}"
client_pub="${2:?需要客户端公钥}"

ssh "root@$vps_ip" "
cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = $client_pub
AllowedIPs = 10.10.0.2/32
EOF
systemctl restart wg-quick@wg0
echo 'Peer 已添加'
"
