#!/usr/bin/env bash

verify_connectivity() {
    ensure_cmd ping
    sleep 2
    ping -c 2 -W 3 10.0.0.1 &>/dev/null
}

print_guide() {
    local server_pub="$1"
    local local_pub="$2"
    local ip="$3"

    header "=== 配置完成 ==="
    cat << EOF

  服务器公钥: $server_pub
  本地公钥:   $local_pub

  ┌──────────┐     ┌──────────┐     ┌──────────┐
  │  本地(L)  │────│ 服务器(S) │────│  远程(R)  │
  │ 10.0.0.2 │    │ 10.0.0.1 │    │ 10.0.0.3 │
  └──────────┘     └──────────┘     └──────────┘

【远程机器配置步骤】
  在远程机器上运行:
  sudo pacman -Sy wireguard-tools
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
  LOCAL_PRIV=\$(cat /etc/wireguard/privatekey)
  REMOTE_PUB=\$(cat /etc/wireguard/publickey)

  cat > /etc/wireguard/wg0.conf << WGEOF
  [Interface]
  Address = 10.0.0.3/24
  PrivateKey = \${LOCAL_PRIV}

  [Peer]
  PublicKey = ${server_pub}
  Endpoint = ${ip}:${WG_PORT}
  AllowedIPs = 10.0.0.0/24
  PersistentKeepalive = 25
WGEOF

  然后执行: wg-quick up wg0

  在服务器上添加远程 peer:
  ssh root@${ip} "tee -a /etc/wireguard/wg0.conf << 'PEER'"
  [Peer]
  PublicKey = <远程公钥>
  AllowedIPs = 10.0.0.3/32
  PEER

  连接本地: ssh user@10.0.0.2
EOF
}
