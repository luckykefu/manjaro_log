#!/usr/bin/env bash

setup_ss_server() {
    ensure_cmd openssl
    ensure_cmd iptables
    local PASSWORD="${1:-$(openssl rand -base64 32)}"
    local PORT="${2:-8388}"

    sudo pacman -S shadowsocks-rust --noconfirm --needed
    sudo mkdir -p /etc/shadowsocks-rust
    sudo tee "/etc/shadowsocks-rust/config.json" > /dev/null << EOF
{
    "server": "0.0.0.0",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "2022-blake3-aes-256-gcm",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF
    sudo systemctl enable --now "shadowsocks-rust-server@config"
    sudo iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
    sudo iptables -A INPUT -p udp --dport "$PORT" -j ACCEPT
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && setup_ss_server "$@"
