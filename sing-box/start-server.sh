#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

CONFIG_DIR="${CONFIG_DIR:-/etc/sing-box}"
VLESS_PORT="${VLESS_PORT:-443}"
TUIC_PORT="${TUIC_PORT:-8443}"

info "停止旧 sing-box 进程..."
killall sing-box 2>/dev/null || true
sleep 1

if command -v systemctl &>/dev/null && pidof systemd &>/dev/null; then
  SERVICE_FILE="/etc/systemd/system/sing-box.service"

  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
Type=simple
ExecStart=/usr/bin/sing-box run -c ${CONFIG_DIR}/config.json
Restart=on-failure
RestartSec=10
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload

  if ! grep -q 'CAP_NET_BIND_SERVICE' "$SERVICE_FILE" 2>/dev/null; then
    sed -i 's/CAP_NET_ADMIN CAP_NET_RAW/CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE/' "$SERVICE_FILE" 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
  fi

  info "启动 sing-box 服务（systemd）..."
  systemctl enable --now sing-box 2>/dev/null || systemctl start sing-box
  sleep 2
  systemctl is-active sing-box >/dev/null || err "sing-box 启动失败"
elif command -v tmux &>/dev/null; then
  info "启动 sing-box 服务（tmux）..."
  tmux new-session -d -s sing-box "sing-box run -c ${CONFIG_DIR}/config.json"
  sleep 2
  tmux has-session -t sing-box 2>/dev/null || err "tmux session 启动失败"
else
  info "启动 sing-box 服务（nohup）..."
  nohup sing-box run -c "${CONFIG_DIR}/config.json" > /var/log/sing-box.log 2>&1 &
  sleep 2
fi

sleep 1
ss -tlnp | grep -q ":${VLESS_PORT} " || err "VLESS 端口 ${VLESS_PORT} 未监听"
ss -ulnp | grep -q ":${TUIC_PORT} "  || err "TUIC 端口 ${TUIC_PORT} 未监听"
info "服务端启动成功"
