#!/usr/bin/env bash
# gpg_gen.sh — 生成 GPG 密钥
# 用法: GPG_PASSPHRASE=<pass> gpg_gen.sh <name> <email>

gpg_gen() {
    local email="${2:?"usage: gpg_gen <name> <email>"}"

    # 1. 检查是否已有该邮箱的密钥
    if gpg --list-keys "$email" &>/dev/null; then
        echo "GPG key for $email already exists, skipping"
        return 0
    fi

    # 2. 创建临时 batch 配置
    local cfg
    cfg=$(mktemp /tmp/gpg_batch.XXXXXX) || { echo "mktemp failed"; return 1; }
    trap "rm -f '$cfg'" RETURN

    cat > "$cfg" <<EOF
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: ${1}
Name-Email: ${2}
Expire-Date: 0
Passphrase: ${GPG_PASSPHRASE}
%commit
EOF

    # 3. 生成密钥
    gpg --batch --generate-key "$cfg" || {
        echo "error: GPG key generation failed"; return 1;
    }
    echo "GPG key generated for $email"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    gpg_gen "$@"
fi
