#!/usr/bin/env bash
# 配置免密码 sudo
# 用法: sudo_nopassword.sh [user]
# 注意: 需要通过 sudo 执行

set -euo pipefail

sudo_nopassword() {
    local target_user="${1:-${SUDO_USER:-$(whoami)}}"
    local sudoer_file="/etc/sudoers.d/${target_user}"

    if [[ -f "$sudoer_file" ]]; then
        local current_perms current_owner
        current_perms=$(stat -c "%a" "$sudoer_file" 2>/dev/null || echo "000")
        current_owner=$(stat -c "%U:%G" "$sudoer_file" 2>/dev/null || echo "unknown")
        if [[ "$current_perms" != "440" ]]; then
            echo "⚠ 文件权限异常: $current_perms (应为 440)"
            echo "⚠ 当前所有者: $current_owner"
        fi
    fi

    echo "$target_user ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoer_file" > /dev/null
    sudo chmod 440 "$sudoer_file"
    sudo chown root:root "$sudoer_file"

    echo "✓ Passwordless sudo configured for user: $target_user"
    echo "  File: $sudoer_file"
    echo "  Permissions: $(stat -c "%a" "$sudoer_file")"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && sudo_nopassword "$@"