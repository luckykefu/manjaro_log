#!/usr/bin/env bash

ss_deploy() {
    ensure_cmd ssh-copy-id openssh
    ensure_cmd scp openssh
    ensure_cmd ssh openssh
    local IP="${1:?'ip is required'}"
    local PORT="${2:-8388}"
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    ssh-copy-id -i ~/.ssh/id_ed25519.pub "root@$IP"
    scp "${SCRIPT_DIR}/server.sh" "root@$IP:~/server.sh"
    ssh "root@$IP" "bash server.sh '' '$PORT'"
    bash "${SCRIPT_DIR}/proxy_config.sh" "$IP"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && ss_deploy "$@"
