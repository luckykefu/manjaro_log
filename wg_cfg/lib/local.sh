#!/usr/bin/env bash
set -euo pipefail

local_configure() {
    local server_pub="$1"

    header "2/4 配置本地机器"

    install_wg
    generate_keys

    local local_priv
    local_priv=$(get_private_key)
    local local_pub
    local_pub=$(get_public_key)
    info "本地公钥: $local_pub"

    cat > "$WG_DIR/wg0.conf" <<EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = ${local_priv}
DNS = 1.1.1.1

[Peer]
PublicKey = ${server_pub}
Endpoint = ${IP}:${WG_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    chmod 600 "$WG_DIR/wg0.conf"

    echo "$local_pub"
}

local_start() {
    info "启动本地 WireGuard..."
    systemctl enable wg-quick@wg0 2>/dev/null || true
    systemctl restart wg-quick@wg0 2>/dev/null && info "WG 已启动 (systemd)" || {
        warn "systemd 不可用，尝试 wg-quick up..."
        wg-quick up wg0 2>/dev/null || warn "请手动启动: wg-quick up wg0"
    }
}
