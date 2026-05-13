#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    local IP="${1:-}"
    local SSH_PORT="${2:-22}"

    [[ -z "$IP" ]] && { err "用法: main.sh <server-ip> [ssh-port]"; exit 1; }

    SSH_OPTS="-p $SSH_PORT -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -i /home/lkf/.ssh/id_ed25519"
    WG_PORT=51820
    WG_DIR=/etc/wireguard

    server_install_and_config
    local server_pub
    server_pub=$(server_fetch_pubkey)
    info "服务器公钥: $server_pub"

    local local_pub
    local_pub=$(local_configure "$server_pub")

    server_exchange_key "$local_pub"

    server_start
    local_start

    verify_connectivity
    print_guide "$server_pub" "$local_pub" "$IP"
}

main "$@"
