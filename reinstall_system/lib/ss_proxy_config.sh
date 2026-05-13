#!/usr/bin/env bash
# ss_proxy_config.sh — 拉取远程 ss 服务端配置，转为本地 sslocal 配置并启动
# 用法: ss_proxy_config <ip> [remote_config]

ss_proxy_config() {
    local IP="${1:?'ip is required'}"
    local REMOTE_CFG="${2:-/etc/shadowsocks-rust/config.json}"
    local CFG=$HOME/.shadowsocks/config.json
    local LOG=$HOME/.shadowsocks/ss.log

    sudo pacman -S --needed --noconfirm shadowsocks-rust jq
    mkdir -p "$(dirname "$CFG")" "$(dirname "$LOG")"

    # 1. 从远程拉取服务端配置
    local TMP
    TMP=$(mktemp)
    scp "root@${IP}:${REMOTE_CFG}" "$TMP" || {
        echo "error: scp failed, check $IP:$REMOTE_CFG"; rm "$TMP"; return 1;
    }

    # 2. 转换为本地客户端配置
    jq --arg ip "$IP" 'del(.mode) | .server = $ip | .local_address = "0.0.0.0" | .local_port = 1080' "$TMP" > "$CFG" || {
        echo "error: jq transform failed"; rm "$TMP"; return 1;
    }
    rm "$TMP"

    # 3. 重启 sslocal
    pkill -f 'sslocal' 2>/dev/null || true
    nohup sslocal -c "$CFG" > "$LOG" 2>&1 &
    sleep 0.5
    pgrep -f 'sslocal' > /dev/null && echo "sslocal started (port 1080)" || echo "warning: sslocal may not have started"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ss_proxy_config "$@"
fi
