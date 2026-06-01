#!/usr/bin/env bash
# ssh_copy_id.sh — 推送本机公钥到远程 root
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

push_pubkey() {
    local ip="$1"
    require_ip "$ip"

    # 生成密钥对（若不存在）
    [[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

    info "清理旧 known_hosts 记录：$ip"
    ssh-keygen -R "$ip" 2>/dev/null || true

    info "推送公钥 → root@${ip}"
    ssh-copy-id -o StrictHostKeyChecking=accept-new \
                -i ~/.ssh/id_ed25519.pub \
                "root@${ip}"
    log "公钥推送完成"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && push_pubkey "${1:?用法: $0 <IP>}"
