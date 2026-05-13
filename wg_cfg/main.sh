#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    local IP="${1:?'usage: main.sh <server-ip> [ssh-port]'}"
    local SSH_PORT="${2:-22}"

    SSH_OPTS="-p $SSH_PORT -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -i /home/lkf/.ssh/id_ed25519"
    WG_PORT=51820
    WG_DIR=/etc/wireguard

    server_install_and_config
    local server_pub
    server_pub=$(server_fetch_pubkey)

    local local_pub
    local_pub=$(local_configure "$server_pub")

    server_exchange_key "$local_pub"
    server_start
    local_start
    verify_connectivity
    print_guide "$server_pub" "$local_pub" "$IP"
}

main "$@"
