#!/usr/bin/env bash

WG_DIR=/etc/wireguard

generate_keys() {
    ensure_cmd wg wireguard-tools
    local dir="${1:-$WG_DIR}"
    mkdir -p "$dir"
    wg genkey | tee "$dir/privatekey" | wg pubkey > "$dir/publickey"
    chmod 600 "$dir/privatekey"
}

get_public_key() {
    local dir="${1:-$WG_DIR}"
    cat "$dir/publickey"
}

get_private_key() {
    local dir="${1:-$WG_DIR}"
    cat "$dir/privatekey"
}
