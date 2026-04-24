#!/bin/bash
setup_git_backup() {
  local FILE=${1:?Usage: $0 <sh_file_path>}
  local NAME=$(basename "$FILE" .sh)
  mkdir -p $(dirname $FILE)
  chmod +x $FILE

  local ServiceFile=~/.config/systemd/user/$NAME.service
  mkdir -p $(dirname $ServiceFile)
  cat > $ServiceFile << EOF
[Unit]
Description=Git Auto Push
After=network.target

[Service]
ExecStart=$FILE
EOF

  local TimerFile=~/.config/systemd/user/$NAME.timer
  cat > $TimerFile << 'EOF'
[Unit]
Description=Git Auto Push Daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now $(basename $TimerFile)
  systemctl --user status $(basename $TimerFile)
  systemctl --user start $(basename $ServiceFile)
  journalctl --user -u $(basename $ServiceFile) -n 50 --no-pager
  systemctl --user list-timers --all
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && setup_git_backup "$1"
