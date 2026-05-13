#!/usr/bin/env bash
# git_config.sh — 配置 git 全局用户名、邮箱、默认分支、GPG 签名
# 用法: git_config [name] [email]
# 默认: name=kefu, email=19157521820@163.com

git_config() {
    local name="${1:-kefu}"
    local email="${2:-19157521820@163.com}"

    # 1. 设置用户名和邮箱
    git config --global user.name "$name" || echo "warning: failed to set user.name"
    git config --global user.email "$email" || echo "warning: failed to set user.email"

    # 2. 设置默认分支为 main
    git config --global init.defaultBranch "main"
    # 3. 设置 credential helper
    if git config --global credential.helper "libsecret" 2>/dev/null; then
        :  # libsecret 可用
    else
        echo "libsecret 不可用，使用 cache 作为 credential helper"
        git config --global credential.helper "cache --timeout=3600"
    fi

    # 4. 配置 GPG 签名
    local signingkey
    signingkey=$(gpg --list-secret-keys --keyid-format LONG "$email" 2>/dev/null \
        | awk '/^sec/{split($2,a,"/"); print a[2]; exit}')
    if [[ -n "$signingkey" ]]; then
        git config --global user.signingkey "$signingkey" || echo "warning: failed to set signingkey"
        git config --global commit.gpgsign true || echo "warning: failed to enable commit.gpgsign"
        echo "已启用 GPG 签名 (key: $signingkey)"
    else
        echo "未找到 $email 的 GPG 密钥，跳过签名配置"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    git_config "$@"
fi
