#!/usr/bin/env bash
# ssh_config.sh — 生成/复制 SSH 密钥
# 用法: ssh_config [email] [ssh_dir]
# 默认: email=19157521820@163.com, ssh_dir=.ssh (相对于脚本目录)

ssh_config() {
    local email="${1:-19157521820@163.com}"
    local ssh_dir="${2:-.ssh}"
    local home_ssh="$HOME/.ssh"

    # 1. 备份现有 ~/.ssh
    if [[ -d "$home_ssh" ]]; then
        local bak="$HOME/.ssh.bak"
        [[ -d "$bak" ]] && rm -rf "$bak"
        mv "$home_ssh" "$bak"
        echo "已备份 $home_ssh → $bak"
    fi

    cd "$(dirname "${BASH_SOURCE[0]}")"

    # 2. 从脚本目录硬链接预置密钥，或生成新密钥
    if [[ -d "$ssh_dir" ]]; then
        mkdir -p "$home_ssh"
        cp -rl "$ssh_dir"/. "$home_ssh"
    else
        mkdir -p "$home_ssh"
        ssh-keygen -t ed25519 -C "$email" -f "$home_ssh/id_ed25519" -N ""
    fi

    # 3. 设置正确权限
    chmod 700 "$home_ssh"
    find "$home_ssh" -name 'id_*' -exec chmod 600 {} +
    find "$home_ssh" -name '*.pub' -exec chmod 644 {} +

    cat "$home_ssh/id_ed25519.pub"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ssh_config "$@"
fi
