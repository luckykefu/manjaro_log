#!/bin/bash
# 从批处理文件生成 GPG 密钥
# 用法: gpg_gen.sh [name] [email] [passphrase]

set -euo pipefail

NAME="${1:-}"
EMAIL="${2:-}"
PASS="${3:-}"

[ -z "$NAME" ] && read -rp "Name: " NAME
[ -z "$EMAIL" ] && read -rp "Email: " EMAIL
[ -z "$PASS" ]  && read -rsp "Passphrase: " PASS && echo

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
