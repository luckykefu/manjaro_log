#!/usr/bin/env bash
# 一键部署 WG 局域网组网 (VPS + 本机)
set -euo pipefail

vps_ip="${1:?用法: $0 <vps-ip>}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 1. 部署服务端 ==="
server_out=$("$dir/deploy_server.sh" "$vps_ip")
server_pub=$(echo "$server_out" | grep -E '^[A-Za-z0-9+/]{40,}={0,2}$' | head -1)
echo "服务端公钥: $server_pub"

echo ""
echo "=== 2. 配置客户端 ==="
client_out=$(bash "$dir/client.sh" "$server_pub" "$vps_ip:51820")
client_pub=$(echo "$client_out" | grep -E '^[A-Za-z0-9+/]{40,}={0,2}$' | head -1)
echo "客户端公钥: $client_pub"

echo ""
echo "=== 3. 添加客户端到服务端 ==="
bash "$dir/peer.sh" "$vps_ip" "$client_pub"

echo ""
echo "=== 4. 验证 ==="
sleep 2
sudo wg show wg0 2>/dev/null || true
echo ""
ping -c 2 -W 3 10.10.0.1 2>&1 | tail -3
echo ""
echo "完成: 本机 10.10.0.2 <-> VPS 10.10.0.1"
