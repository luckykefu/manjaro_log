#!/usr/bin/env bash
# gpg_gen.sh — 生成 GPG 密钥
# 用法: GPG_PASSPHRASE=<pass> gpg_gen.sh <name> <email>

gpg_gen() {
    local name="${1:?"usage: gpg_gen <name> <email>"}"
    local email="${2:?"usage: gpg_gen <name> <email>"}"
    local gnupg_dir
    gnupg_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.gnupg"
    local home_gnupg="$HOME/.gnupg"

    # 1. 检查源目录是否已有该邮箱密钥
    if [[ -f "$gnupg_dir/pubring.kbx" ]] && gpg --homedir "$gnupg_dir" --list-keys "$email" &>/dev/null; then
        echo "GPG key for $email already exists, skipping"
    else
        mkdir -p -m 700 "$gnupg_dir"

        local cfg
        cfg=$(mktemp /tmp/gpg_batch.XXXXXX) || { echo "mktemp failed"; return 1; }
        trap "rm -f '$cfg'" RETURN

        cat > "$cfg" <<EOF
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: ${name}
Name-Email: ${email}
Expire-Date: 0
Passphrase: ${GPG_PASSPHRASE}
%commit
EOF

        gpg --homedir "$gnupg_dir" --batch --generate-key "$cfg" || {
            echo "error: GPG key generation failed"; return 1;
        }
        echo "GPG key generated for $email"
    fi

    # 2. 备份现有 ~/.gnupg
    if [[ -d "$home_gnupg" ]] && [[ ! -L "$home_gnupg" ]]; then
        local bak="$HOME/.gnupg.bak"
        [[ -d "$bak" ]] && rm -rf "$bak"
        mv "$home_gnupg" "$bak"
        echo "已备份 $home_gnupg → $bak"
    fi

    # 3. 创建软链接
    chmod 700 "$gnupg_dir"
    ln -sf "$gnupg_dir" "$home_gnupg"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    gpg_gen "$@"
fi
