#!/usr/bin/env bash
# 从批处理文件生成 GPG 密钥
# 用法: GPG_PASSPHRASE=<pass> gpg_gen.sh [name] [email]
# 或: gpg_gen.sh [name] [email] (交互式输入)

set -euo pipefail

gpg_gen() {
    local NAME="${1:-}"
    local EMAIL="${2:-}"

    [[ -z "$NAME" ]] && read -rp "Name: " NAME
    [[ -z "$EMAIL" ]] && read -rp "Email: " EMAIL

    if gpg --list-keys "$EMAIL" &>/dev/null; then
        echo "✓ GPG 密钥已存在 ($EMAIL)，跳过"
        return
    fi

    local PASS
    if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
        PASS="${GPG_PASSPHRASE}"
        echo "✓ 使用环境变量 GPG_PASSPHRASE"
    else
        read -rsp "Passphrase: " PASS && echo
    fi

    local CFG
    CFG=$(mktemp /tmp/gpg_batch.XXXXXX)
    trap 'rm -f "$CFG"' EXIT

    cat > "$CFG" <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${NAME}
Name-Email: ${EMAIL}
Expire-Date: 0
Passphrase: ${PASS}
%commit
%echo Done
EOF

    gpg --batch --generate-key "$CFG"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && gpg_gen "$@"