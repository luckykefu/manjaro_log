## /data/.cryptomator

```bash
%%bash
FILE=/data/.cryptomator/auto-push.sh
mkdir -p $(dirname $FILE)

cat > $FILE << 'EOF'
#!/bin/bash
DIRS=(
  /data/.cryptomator
  /data/.manjaro
  /data/projects_ING/SMC
  /data/projects_ING/freqtrade_trade
)
for DIR in "${DIRS[@]}"; do
  if [[ -d "$DIR/.git" ]]; then
    echo "=== 正在处理: $DIR ==="
    cd "$DIR" && git add -A && git diff --cached --quiet || git commit -m "$(date '+%Y-%m-%d')" && git push
  else
    echo "=== 跳过: $DIR (不是 git 仓库或未挂载) ==="
  fi
done
EOF
chmod +x $FILE

ServiceFile=~/.config/systemd/user/git-backup.service
mkdir -p $(dirname $ServiceFile)
cat > $ServiceFile << EOF
[Unit]
Description=Git Auto Push
After=network.target

[Service]
ExecStart=$FILE
EOF

TimerFile=~/.config/systemd/user/git-backup.timer
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
```
