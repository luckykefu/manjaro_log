#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*" >&2; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

CERT_DIR="${1:-/etc/sing-box/cert}"

info "生成 Reality keypair..."
REALITY_KEYS=$(sing-box generate reality-keypair)
PRIVATE_KEY=$(echo "$REALITY_KEYS" | awk '/PrivateKey:/ {print $2}')
PUBLIC_KEY=$(echo "$REALITY_KEYS" | awk '/PublicKey:/ {print $2}')
[[ -n "$PRIVATE_KEY" && -n "$PUBLIC_KEY" ]] || err "生成 Reality keypair 失败"

info "生成 UUID..."
VLESS_UUID=$(sing-box generate uuid)
TUIC_UUID=$(sing-box generate uuid)

info "生成 TUIC 密码..."
TUIC_PASSWORD=$(openssl rand -base64 16)
SHORT_ID=$(openssl rand -hex 4)

info "生成 TUIC 自签名证书..."
mkdir -p "$CERT_DIR"
openssl ecparam -genkey -name prime256v1 -out "${CERT_DIR}/tuic.key" 2>/dev/null
openssl req -x509 -key "${CERT_DIR}/tuic.key" -out "${CERT_DIR}/tuic.pem" \
  -days 3650 -subj "/CN=sing-box-tuic/O=sing-box" 2>/dev/null

echo "export PRIVATE_KEY=\"$PRIVATE_KEY\""
echo "export PUBLIC_KEY=\"$PUBLIC_KEY\""
echo "export VLESS_UUID=\"$VLESS_UUID\""
echo "export TUIC_UUID=\"$TUIC_UUID\""
echo "export TUIC_PASSWORD=\"$TUIC_PASSWORD\""
echo "export SHORT_ID=\"$SHORT_ID\""
