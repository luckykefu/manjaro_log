#!/usr/bin/env bash
set -euo pipefail

WG_DIR=/etc/wireguard

generate_keys() {
    local dir="${1:-$WG_DIR}"
    mkdir -p "$dir"
    if [[ ! -s "$dir/privatekey" ]]; then
        wg genkey | tee "$dir/privatekey" | wg pubkey > "$dir/publickey"
    fi
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
