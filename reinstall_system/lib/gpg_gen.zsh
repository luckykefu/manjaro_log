# gpg_gen.zsh — 生成 GPG 密钥
# DOC:
#   1. 检查脚本目录 .gnupg/ 是否已有该邮箱密钥，有则跳过
#   2. 无则用 eddsa/ed25519 批量生成密钥（从环境变量 GPG_PASSPHRASE 读取密码）
#   3. 备份现有 ~/.gnupg → ~/.gnupg.bak
#   4. 创建软链接到脚本目录 .gnupg/
# 用法: GPG_PASSPHRASE=<pass> gpg_gen.sh <name> <email>

gpg_gen() {
    local name="${1:?"usage: gpg_gen <name> <email>"}"
    local email="${2:?"usage: gpg_gen <name> <email>"}"
    local gnupg_dir
    gnupg_dir="${funcfiletrace[1]:h}/.gnupg"
    local home_gnupg="$HOME/.gnupg"

    # 1. 检查脚本目录是否已有该邮箱密钥
    if [[ -f "$gnupg_dir/pubring.kbx" ]] && gpg --homedir "$gnupg_dir" --list-keys "$email" &>/dev/null; then
        echo "GPG key for $email already exists, skipping"
    else
        # 1a. 创建 .gnupg 目录
        mkdir -p -m 700 "$gnupg_dir"

        # 1b. 生成批处理配置文件
        local cfg
        cfg=$(mktemp /tmp/gpg_batch.XXXXXX) || return 1
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

        # 1c. 批量生成密钥
        gpg --homedir "$gnupg_dir" --batch --generate-key "$cfg" || return 1
        echo "GPG key generated for $email"
    fi

    # 2. 备份现有 ~/.gnupg（非软链接）
    if [[ -d "$home_gnupg" ]] && [[ ! -L "$home_gnupg" ]]; then
        local bak="$HOME/.gnupg.bak"
        [[ -d "$bak" ]] && rm -rf "$bak"
        mv "$home_gnupg" "$bak"
        echo "已备份 $home_gnupg → $bak"
    fi

    # 3. 创建软链接到脚本目录
    chmod 700 "$gnupg_dir"
    backup_sf "$gnupg_dir" "$home_gnupg"
}

