#!/bin/bash
# ============================================================================
# Script: git_conf.sh
# Description: Configure global Git settings including user info and GPG signing
# Logic: Retrieves GPG signing key from system, configures Git with user name,
#        email, default branch, GPG program, signing key, and credential helper
# ============================================================================
# 脚本: git_conf.sh
# 描述: 配置全局 Git 设置，包括用户信息和 GPG 签名
# 逻辑: 从系统获取 GPG 签名密钥，配置 Git 用户名、邮箱、默认分支、GPG 程序、
#        签名密钥和凭据助手
# ============================================================================

git_conf() {
    local name=${1:-"kefu"}
    local email=${2:-"19157521820@163.com"}
    local signingkey=$(gpg --list-secret-keys --keyid-format SHORT 2>/dev/null | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)

    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch "main"
    git config --global gpg.program "gpg"
    git config --global user.signingkey "$signingkey"
    git config --global commit.gpgsign "false"
    git config --global credential.helper "store"
    
    echo "✓ Git configured"
}