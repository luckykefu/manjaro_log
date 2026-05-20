#! /usr/bin/env bash
set -euo pipefail

ssh_copy_id(){
    local ip=${1:? IP?}
    ssh-keygen -R "$ip"
    ssh-copy-id -o StrictHostKeyChecking=accept-new "root@${ip}"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ssh_copy_id "$@"
fi
