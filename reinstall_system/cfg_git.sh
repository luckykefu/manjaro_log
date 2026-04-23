#!/usr/bin/env bash
set -euo pipefail

cfg_git() {
    local name="${1:-kefu}"
    local email="${2:-19157521820@163.com}"
    
    # 获取 GPG 签名密钥
    local signingkey=$(gpg --list-secret-keys --keyid-format SHORT "$email" 2>/dev/null | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)
    
    # 配置 Git
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch "main"
    git config --global credential.helper "store"
    
    # 配置 GPG 签名(如果密钥存在)
    if [[ -n "$signingkey" ]]; then
        git config --global gpg.program "gpg"
        git config --global user.signingkey "$signingkey"
        git config --global commit.gpgsign "false"
        echo "✓ Git configured with GPG key: $signingkey"
    else
        echo "⚠ 未找到 GPG 密钥,跳过签名配置"
        echo "✓ Git configured"
    fi
}

cfg_git "$@"
