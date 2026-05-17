#!/usr/bin/env bash
gen_ss_cfg(){
    local PASS
    PASS=$(ssservice genkey -m "2022-blake3-aes-256-gcm")
    sudo mkdir -p /etc/shadowsocks-rust
    sudo tee /etc/shadowsocks-rust/config.json << EOF
    {
        "server": "0.0.0.0",
        "server_port": 8388,
        "password": "${PASS}",
        "method": "2022-blake3-aes-256-gcm",
        "mode": "tcp_and_udp"
    }
EOF
}
ss_systemd_cfg(){
    # 停掉并禁用所有已有实例
    sudo systemctl stop    'shadowsocks-rust-server@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust-server@*' 2>/dev/null || true
    # 启动新的 config 实例
    sudo systemctl enable --now shadowsocks-rust-server@config.service
}
port_open() {
    local port="${1:-8388}"
    local proto="${2:-tcp}"

    if command -v firewall-cmd &>/dev/null; then
        echo "==> firewalld  detected"
        sudo firewall-cmd --add-port="${port}/${proto}" --permanent 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
    elif command -v ufw &>/dev/null; then
        echo "==> ufw detected"
        sudo ufw allow "${port}/${proto}" 2>/dev/null || true
    elif command -v iptables &>/dev/null; then
        echo "==> iptables detected"
        sudo iptables -C INPUT -p "${proto}" --dport "${port}" -j ACCEPT 2>/dev/null ||
            sudo iptables -A INPUT -p "${proto}" --dport "${port}" -j ACCEPT
    else
        echo "==> 未检测到防火墙工具，跳过"
    fi
}
sudo pacman -S --needed --noconfirm shadowsocks-rust
gen_ss_cfg
ss_systemd_cfg
port_open
sudo systemctl status shadowsocks-rust-server@config.service
ss -tlnp | grep 8388
