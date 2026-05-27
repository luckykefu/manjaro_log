## /data/.cryptomator

```bash
%%bash
FILE=/data/.cryptomator/auto-push.sh

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
