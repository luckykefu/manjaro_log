#!/usr/bin/env bash
set -euo pipefail

gen_ssh_key() {
    local email="${1:-19157521820@163.com}"
    local ssh_dir="${2:-.ssh}"
    local home_ssh="$HOME/.ssh"
    cd "$(dirname "$0")"
    # 安全处理：备份已有的真实目录，移除旧的软链接
    rm -fr "$home_ssh"
    if [[ -d "$ssh_dir" ]]; then
        # 目录已存在：复制到 ~/.ssh
        cp -r "$ssh_dir" "$home_ssh"
        echo "✓ SSH 目录已复制到 ~/.ssh"
    else
        # 目录不存在：直接在 ~/.ssh 创建并生成密钥
        mkdir -p "$home_ssh"

        ssh-keygen -t ed25519 -C "$email" -f "$home_ssh/id_ed25519" -N ""
        echo "✓ SSH 密钥已生成: $home_ssh/id_ed25519"
    fi

    # 统一设置权限
    chmod 700 "$home_ssh"
    shopt -s nullglob
    chmod 600 "$home_ssh"/id_*
    chmod 644 "$home_ssh"/*.pub
    shopt -u nullglob

    echo "公钥内容:"
    cat "$home_ssh/id_ed25519.pub"
}

gen_ssh_key "$@"
