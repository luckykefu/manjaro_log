#!/bin/bash
# 用法: ./ss_local.sh [服务器IP] [密码]

IP="${1:-202.182.112.91}"
PASSWORD="${2:-lkf.Vpn.mima3}"
cfg=$HOME/.shadowsocks/config.json
pid=$HOME/.shadowsocks/ss.pid
log=$HOME/.shadowsocks/ss.log

sudo pacman -S --needed --noconfirm shadowsocks

mkdir -p $(dirname $cfg)
cat > $cfg << EOF
{
    "server": "$IP",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "$PASSWORD",
    "method": "aes-256-gcm",
    "timeout": 300,
    "fast_open": false
}
EOF

pkill -f sslocal 2>/dev/null
sslocal -c $cfg -d start --pid-file $pid --log-file $log
sleep 1
echo "sslocal pid: $(cat $pid 2>/dev/null)"
