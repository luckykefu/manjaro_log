#!/bin/bash
# 拉取远程 ss 服务端配置，转为本地 sslocal 配置并启动
# 用法: ss_local <ip> [remote_config=/etc/shadowsocks-rust/config.json]

set -euo pipefail

ss_local() {
    local IP="${1:?'ip is required'}"
    local REMOTE_CFG="${2:-/etc/shadowsocks-rust/config.json}"
    local CFG=$HOME/.shadowsocks/config.json
    local PID=$HOME/.shadowsocks/ss.pid
    local LOG=$HOME/.shadowsocks/ss.log

    mkdir -p "$(dirname "$CFG")"

    # 拉取远程配置，提取 server_port/password/method
    local TMP=$(mktemp)
    scp "root@${IP}:${REMOTE_CFG}" "$TMP"

    # 服务端配置转本地配置
    jq --arg ip "$IP" '
        del(.mode) |
        .server = $ip |
        .local_address = "0.0.0.0" |
        .local_port = 1080
    ' "$TMP" > "$CFG"
    rm "$TMP"

    pkill -f sslocal 2>/dev/null || true
    nohup sslocal -c "$CFG" > "$LOG" 2>&1 &
    echo $! > "$PID"
    sleep 1
    echo "sslocal pid: $(cat "$PID")"
    cat "$CFG"

    # 测试代理连通性
    echo "🔗 测试代理..."
    curl --socks5-hostname 127.0.0.1:1080 https://www.google.com -I --max-time 10 -s -o /dev/null -w "%{http_code}\n"
}

ss_local "$@"
