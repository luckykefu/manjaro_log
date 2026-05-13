#!/usr/bin/env bash

ss_local() {
    local IP="${1:?'ip is required'}"
    local REMOTE_CFG="${2:-/etc/shadowsocks-rust/config.json}"
    local CFG=$HOME/.shadowsocks/config.json
    local LOG=$HOME/.shadowsocks/ss.log

    ensure_cmd scp openssh
    ensure_cmd jq
    ensure_cmd sslocal shadowsocks-rust

    sudo pacman -Sy --needed --noconfirm shadowsocks-rust
    mkdir -p "$(dirname "$CFG")" "$(dirname "$LOG")"

    local TMP
    TMP=$(mktemp)
    scp "root@${IP}:${REMOTE_CFG}" "$TMP"
    jq --arg ip "$IP" 'del(.mode) | .server = $ip | .local_address = "0.0.0.0" | .local_port = 1080' "$TMP" > "$CFG"
    rm "$TMP"

    pkill -f sslocal 2>/dev/null || true
    nohup sslocal -c "$CFG" > "$LOG" 2>&1 &
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && ss_local "$@"
