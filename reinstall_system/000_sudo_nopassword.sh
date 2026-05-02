#!/bin/bash
set -euo pipefail

sudo_nopassword() {
    # 为当前用户配置 sudo 免密，写入 /etc/sudoers.d/ 并校验语法
    local user="${SUDO_USER:-$(logname)}"
    [[ -z "$user" ]] && { echo "❌ Cannot determine user"; return 1; }

    local sudoers_file="/etc/sudoers.d/${user}_nopasswd"
    echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" >/dev/null  # 写入免密规则

    if ! sudo visudo -c -f "$sudoers_file" >/dev/null 2>&1; then  # 校验语法
        sudo rm -f "$sudoers_file"
        echo "❌ Invalid sudoers syntax"
        return 1
    fi

    sudo chmod 440 "$sudoers_file"  # sudoers 文件必须 440 权限
    echo "✓ Sudo no password configured for $user"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && sudo_nopassword  # 直接执行时调用
