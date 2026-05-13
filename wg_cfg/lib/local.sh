#!/usr/bin/env bash

local_configure() {
    ensure_cmd wg wireguard-tools
    ensure_cmd systemctl
    local server_pub="$1"

    install_wg
    generate_keys

    local local_priv
    local_priv=$(get_private_key)
    local local_pub
    local_pub=$(get_public_key)

    cat > "$WG_DIR/wg0.conf" << EOF
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
    ensure_cmd systemctl
    systemctl enable wg-quick@wg0 2>/dev/null || true
    systemctl restart wg-quick@wg0 2>/dev/null || wg-quick up wg0 2>/dev/null || true
}
