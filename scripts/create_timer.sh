#!/usr/bin/env bash

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "${COMMON_DIR}/common.sh"
# 为指定脚本创建 systemd 用户定时器（每日 00:00 执行）

setup_git_backup() {
    ensure_cmd systemctl
  local file="${1:?Usage: $0 <sh_file_path>}"
  local name
  name="$(basename "$file" .sh)"
  local user_dir="$HOME/.config/systemd/user"

  mkdir -p "$(dirname "$file")" "$user_dir"
  chmod +x "$file"

  cat > "${user_dir}/${name}.service" << EOF
[Unit]
Description=Git Auto Push
After=network.target

[Service]
ExecStart=${file}
EOF

  cat > "${user_dir}/${name}.timer" << 'EOF'
[Unit]
Description=Git Auto Push Daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now "${name}.timer"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && setup_git_backup "$1"
