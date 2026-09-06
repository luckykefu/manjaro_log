#!/usr/bin/env bash
# Colab 端：安装 shadowsocks-rust 并启动服务端
set -euo pipefail

readonly SS_PORT=8388
readonly SS_CFG=/etc/shadowsocks-rust/config.json
readonly SS_METHOD="2022-blake3-aes-256-gcm"

readonly SS_VERSION="1.24.0"

install() {
    echo "安装 shadowsocks-rust v${SS_VERSION}..."
    sudo apt update -qq && sudo apt install -y -qq curl xz-utils

    curl -sL "https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${SS_VERSION}/shadowsocks-v${SS_VERSION}.x86_64-unknown-linux-gnu.tar.xz" \
      | sudo tar xJ -C /usr/local/bin ssserver ssservice
    echo "已安装: $(ssserver --version)"
}

gen_config() {
    local pass
    pass=$(ssservice genkey -m "$SS_METHOD")
    sudo mkdir -p "$(dirname "$SS_CFG")"
    sudo tee "$SS_CFG" > /dev/null << EOF
{
    "server":      "0.0.0.0",
    "server_port": ${SS_PORT},
    "password":    "${pass}",
    "method":      "${SS_METHOD}",
    "mode":        "tcp_and_udp"
}
EOF
    echo "配置写入 $SS_CFG"
    cat "$SS_CFG"
}

start_server() {
    echo "启动 ssserver..."
    sudo pkill ssserver 2>/dev/null || true
    sudo -b nohup ssserver -c "$SS_CFG" > /tmp/ssserver.log 2>&1
    sleep 1
    ss -tlnp | grep ":${SS_PORT} " || echo "警告：端口 $SS_PORT 未监听"
    echo "服务端就绪 ✓"
}

install
gen_config
start_server
