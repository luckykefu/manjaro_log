#!/usr/bin/env bash
set -euo pipefail

cfg_git() {
    local name="${1:-kefu}"
    local email="${2:-19157521820@163.com}"

    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch "main"
    git config --global credential.helper "libsecret"

    # 查找该 email 对应的 GPG 私钥 ID
    local signingkey
    signingkey=$(gpg --list-secret-keys --keyid-format LONG "$email" 2>/dev/null | \
        awk '/^sec/{split($2,a,"/"); print a[2]; exit}')

    if [[ -n "$signingkey" ]]; then
        git config --global gpg.program "gpg"
        git config --global user.signingkey "$signingkey"
        git config --global commit.gpgsign true
        echo "✓ GPG signing enabled (key: $signingkey)"
    else
        echo "⚠ 未找到 GPG 密钥,跳过签名配置"
    fi
    
    echo "✓ Git configured"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && cfg_git "$@"
