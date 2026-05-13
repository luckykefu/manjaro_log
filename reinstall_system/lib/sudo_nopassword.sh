#!/usr/bin/env bash
# 配置免密码 sudo
# 用法: sudo_nopassword.sh [user]

sudo_nopassword() {
    command -v sudo &>/dev/null || return 1

    local user="${1:-${SUDO_USER:-$(whoami)}}"

    [[ -z "$user" ]] && { echo "error: empty username"; return 1; }

    id "$user" &>/dev/null || { echo "error: user $user does not exist"; return 1; }

    [[ "$user" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]] || { echo "error: invalid username $user"; return 1; }

    local sudoers_dir="/etc/sudoers.d"
    local sudoers_file="$sudoers_dir/$user"

    echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null || {
        echo "error: failed to write $sudoers_file"; return 1;
    }

    sudo chmod 0440 "$sudoers_file" || {
        echo "error: failed to set permissions on $sudoers_file"; return 1;
    }

    echo "已为用户 $user 配置免密码 sudo"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    sudo_nopassword "$@"
fi
