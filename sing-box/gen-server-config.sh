#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

: "${PRIVATE_KEY:?未设置 PRIVATE_KEY}"
: "${VLESS_UUID:?未设置 VLESS_UUID}"
: "${TUIC_UUID:?未设置 TUIC_UUID}"
: "${TUIC_PASSWORD:?未设置 TUIC_PASSWORD}"
: "${SHORT_ID:?未设置 SHORT_ID}"

VLESS_PORT="${VLESS_PORT:-443}"
TUIC_PORT="${TUIC_PORT:-8443}"
REALITY_SNI="${REALITY_SNI:-www.google.com}"
TUIC_CERT_CN="${TUIC_CERT_CN:-sing-box-tuic}"
CONFIG_DIR="${CONFIG_DIR:-/etc/sing-box}"
CERT_DIR="${CERT_DIR:-${CONFIG_DIR}/cert}"

if [[ -f "${CONFIG_DIR}/config.json" ]]; then
  cp "${CONFIG_DIR}/config.json" "${CONFIG_DIR}/config.json.bak.$(date +%Y%m%d-%H%M%S)"
  info "旧服务端配置已备份"
fi

info "写入服务端配置..."
cat > "${CONFIG_DIR}/config.json" << EOF
{
  "log": { "level": "info" },
  "dns": {
    "servers": [{ "type": "tls", "tag": "google", "server": "8.8.8.8" }]
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ${VLESS_PORT},
      "users": [{
        "name": "vless-user",
        "uuid": "${VLESS_UUID}",
        "flow": ""
      }],
      "tls": {
        "enabled": true,
        "server_name": "${REALITY_SNI}",
        "reality": {
          "enabled": true,
          "handshake": { "server": "${REALITY_SNI}", "server_port": 443 },
          "private_key": "${PRIVATE_KEY}",
          "short_id": ["${SHORT_ID}"]
        }
      }
    },
    {
      "type": "tuic",
      "tag": "tuic-in",
      "listen": "::",
      "listen_port": ${TUIC_PORT},
      "users": [{
        "name": "tuic-user",
        "uuid": "${TUIC_UUID}",
        "password": "${TUIC_PASSWORD}"
      }],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "server_name": "${TUIC_CERT_CN}",
        "key_path": "${CERT_DIR}/tuic.key",
        "certificate_path": "${CERT_DIR}/tuic.pem"
      }
    }
  ],
  "outbounds": [{ "type": "direct" }],
  "route": {
    "rules": [{ "port": 53, "action": "hijack-dns" }]
  }
}
EOF

info "验证服务端配置..."
sing-box check -c "${CONFIG_DIR}/config.json" || err "服务端配置验证失败"
