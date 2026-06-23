#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

CONFIG_DIR="${CONFIG_DIR:-/etc/sing-box}"
MIXED_PORT="${MIXED_PORT:-1080}"

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
ExecStart=/usr/bin/sing-box run -c ${CONFIG_DIR}/client.json
Restart=on-failure
RestartSec=10
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload

  info "启动 sing-box 客户端（systemd）..."
  systemctl enable --now sing-box 2>/dev/null || systemctl start sing-box
  sleep 2
  systemctl is-active sing-box >/dev/null || err "sing-box 启动失败"
elif command -v tmux &>/dev/null; then
  info "启动 sing-box 客户端（tmux）..."
  tmux new-session -d -s sing-box "sing-box run -c ${CONFIG_DIR}/client.json"
  sleep 2
  tmux has-session -t sing-box 2>/dev/null || err "tmux session 启动失败"
else
  info "启动 sing-box 客户端（nohup）..."
  nohup sing-box run -c "${CONFIG_DIR}/client.json" > /var/log/sing-box.log 2>&1 &
  sleep 2
fi

sleep 1
ss -tlnp | grep -q ":${MIXED_PORT} " || err "混合代理端口 ${MIXED_PORT} 未监听"
info "客户端启动成功"
