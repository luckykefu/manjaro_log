#! /usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

source ./port_open.sh

install() {
    echo "==> 安装 shadowsocks-rust + jq..."
    sudo pacman -S --needed --noconfirm shadowsocks-rust jq

    echo "==> 获取公网 IP..."
    local ip
    ip=$(curl -s --connect-timeout 5 ifconfig.me || curl -s --connect-timeout 5 icanhazip.com)
    [[ -z "$ip" ]] && ip="0.0.0.0"

    echo "==> 生成 AEAD-2022 密钥..."
    local key
    key=$(ssservice genkey -m "2022-blake3-aes-256-gcm")

    echo "==> 写入服务端 config.json..."
    jq --arg ip "$ip" --arg key "$key" '
        .server = $ip |
        .password = $key
    ' config.example.json > config.json

    echo "==> 开放端口 8388 (TCP+UDP)..."
    port_open 8388 tcp
    port_open 8388 udp

    local cfg_path
    cfg_path="$(pwd)/config.json"

    echo "==> 配置 systemd 服务..."
    sudo tee /etc/systemd/system/ssserver-rust.service > /dev/null <<EOF
[Unit]
Description=Shadowsocks-rust Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ssserver -c ${cfg_path}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload

    if systemctl is-active ssserver-rust.service &>/dev/null; then
        echo "==> 服务已运行，重启..."
        sudo systemctl restart ssserver-rust.service
    else
        echo "==> 启动服务..."
        sudo systemctl enable --now ssserver-rust.service
    fi

    echo ""
    echo "========== 服务端部署完成 =========="
    echo "  服务器: ${ip}:8388"
    echo "  加密:   2022-blake3-aes-256-gcm"
    echo "  密码:   ${key}"
    echo "===================================="
    echo "本地客户端配置生成:"
    echo "  ./main.sh gencfg --server ${ip} --password ${key}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install "$@"
fi
