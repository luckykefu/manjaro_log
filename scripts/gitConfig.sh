#!/usr/bin/env bash
set -euo pipefail

cfg_git() {
    # 配置 git 全局用户信息和 GPG 签名（密钥存在时自动启用）
    # $1: name (可选, 默认 kefu), $2: email (可选)
    local name="${1:-kefu}"
    local email="${2:-19157521820@163.com}"

    # 查找该 email 对应的 GPG 私钥 ID
    local signingkey=$(gpg --list-secret-keys --keyid-format SHORT "$email" 2>/dev/null | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)

    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch "main"   # 默认分支名
    git config --global credential.helper "store"   # 凭证持久化到磁盘

    if [[ -n "$signingkey" ]]; then
        git config --global gpg.program "gpg"
        git config --global user.signingkey "$signingkey"
    else
        echo "⚠ 未找到 GPG 密钥,跳过签名配置"
        echo "✓ Git configured"
    fi
}

cfg_git "$@"
