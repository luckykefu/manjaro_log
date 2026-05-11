#!/usr/bin/env bash
set -euo pipefail

gen_ssh_key() {
    # 生成 ed25519 SSH 密钥，设置权限，并软链接到 ~/.ssh
    # $1: email (可选), $2: ssh_dir (可选, 默认 /run/media/manjaro/data/.home/.ssh)
    local email="${1:-19157521820@163.com}"
    local ssh_dir="${2:-/run/media/manjaro/data/.home/.ssh}"

    mkdir -p "${ssh_dir}"  # 创建 SSH 目录

    if [[ ! -f "${ssh_dir}/id_ed25519" ]]; then
        ssh-keygen -t ed25519 -C "${email}" -f "${ssh_dir}/id_ed25519" -N ""  # 无密码保护
        echo "✓ SSH 密钥已生成: ${ssh_dir}/id_ed25519"
    else
        echo "⚠ SSH 密钥已存在,跳过生成"
    fi

    chmod 700 "${ssh_dir}"          # 目录仅owner可访问
    shopt -s nullglob
    chmod 600 "${ssh_dir}"/id_*     # 私钥仅owner可读写
    chmod 644 "${ssh_dir}"/*.pub    # 公钥可公开读
    shopt -u nullglob

    [ ! -L ~/.ssh ] && rm -rf ~/.ssh
    ln -sf "${ssh_dir}" ~/.ssh      # 软链接到 ~/.ssh
    echo "✓ SSH 目录已链接到 ~/.ssh"
    echo "公钥内容:"
    cat "${ssh_dir}/id_ed25519.pub"
}

gen_ssh_key "$@"
