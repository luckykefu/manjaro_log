#!/usr/bin/env bash
set -euo pipefail

gen_ssh_key() {
    local email="${1:-19157521820@163.com}"
    local ssh_dir="${2:-/data/.home/.ssh}"
    
    # 创建 SSH 目录
    mkdir -p "${ssh_dir}"
    
    # 生成密钥(如果不存在)
    if [[ ! -f "${ssh_dir}/id_ed25519" ]]; then
        ssh-keygen -t ed25519 -C "${email}" -f "${ssh_dir}/id_ed25519" -N ""
        echo "✓ SSH 密钥已生成: ${ssh_dir}/id_ed25519"
    else
        echo "⚠ SSH 密钥已存在,跳过生成"
    fi
    
    # 设置权限
    chmod 700 "${ssh_dir}"
    chmod 600 "${ssh_dir}"/id_*
    chmod 644 "${ssh_dir}"/*.pub
    
    # 链接到主目录
    ln -sf "${ssh_dir}" ~/.ssh
    echo "✓ SSH 目录已链接到 ~/.ssh"
    echo "公钥内容:"
    cat "${ssh_dir}/id_ed25519.pub"
}

gen_ssh_key "$@"
