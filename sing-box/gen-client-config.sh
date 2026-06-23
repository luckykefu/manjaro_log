#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

: "${SERVER_IP:?未设置 SERVER_IP}"
: "${VLESS_PORT:?未设置 VLESS_PORT}"
: "${VLESS_UUID:?未设置 VLESS_UUID}"
: "${PUBLIC_KEY:?未设置 PUBLIC_KEY}"
: "${SHORT_ID:?未设置 SHORT_ID}"
: "${TUIC_PORT:?未设置 TUIC_PORT}"
: "${TUIC_UUID:?未设置 TUIC_UUID}"
: "${TUIC_PASSWORD:?未设置 TUIC_PASSWORD}"

REALITY_SNI="${REALITY_SNI:-www.google.com}"
TUIC_CERT_CN="${TUIC_CERT_CN:-sing-box-tuic}"
CONFIG_DIR="${CONFIG_DIR:-/etc/sing-box}"

info "写入客户端配置..."
mkdir -p "${CONFIG_DIR}"
cat > "${CONFIG_DIR}/client.json" << EOF
{
  "log": { "level": "warn" },
  "dns": {
    "servers": [
      { "tag": "dns-local", "type": "udp", "server": "223.5.5.5" }
    ],
    "final": "dns-local",
    "strategy": "prefer_ipv4"
  },
  "inbounds": [{
    "type": "mixed",
    "tag": "mixed-in",
    "listen": "127.0.0.1",
    "listen_port": 1080
  }],
  "outbounds": [
    {
      "tag": "vless-reality",
      "type": "vless",
      "server": "${SERVER_IP}",
      "server_port": ${VLESS_PORT},
      "uuid": "${VLESS_UUID}",
      "flow": "",
      "tls": {
        "enabled": true,
        "server_name": "${REALITY_SNI}",
        "utls": { "enabled": true, "fingerprint": "chrome" },
        "reality": {
          "enabled": true,
          "public_key": "${PUBLIC_KEY}",
          "short_id": "${SHORT_ID}"
        }
      }
    },
    {
      "tag": "tuic",
      "type": "tuic",
      "server": "${SERVER_IP}",
      "server_port": ${TUIC_PORT},
      "uuid": "${TUIC_UUID}",
      "password": "${TUIC_PASSWORD}",
      "tls": { "enabled": true, "server_name": "${TUIC_CERT_CN}", "insecure": true }
    },
    {
      "type": "selector",
      "tag": "auto",
      "outbounds": ["vless-reality", "tuic"],
      "default": "vless-reality"
    },
    {
      "type": "urltest",
      "tag": "best",
      "outbounds": ["vless-reality", "tuic"],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "5m",
      "tolerance": 50
    },
    { "type": "direct", "tag": "direct" }
  ],
  "route": {
    "rules": [
      { "ip_is_private": true, "outbound": "direct" },
      { "rule_set": "geosite-geolocation-cn", "outbound": "direct" }
    ],
    "rule_set": [{
      "tag": "geosite-geolocation-cn",
      "type": "local",
      "format": "binary",
      "path": "/etc/sing-box/rule-set/geosite-geolocation-cn.srs"
    }],
    "final": "auto"
  }
}
EOF

info "验证客户端配置..."
sing-box check -c "${CONFIG_DIR}/client.json" || err "客户端配置验证失败"
