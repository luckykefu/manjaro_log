#! /usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

deploy() {
    local url="$1"
    sudo pacman -S --needed --noconfirm archlinuxcn/mihomo

    echo "==> 通过 shadowsocks 代理下载订阅配置..."
    curl -s \
        -A 'clash.meta' \
        -o config.yaml "$url"

    echo "==> 订阅配置已保存到 $PWD/config.yaml"
}

port_open() {
    local port
    port=$(sed -n 's/^mixed-port: *\([0-9]*\)/\1/p' "$PWD/config.yaml")
    [[ -z "$port" ]] && port=7890
    local proto=tcp

    if command -v firewall-cmd &>/dev/null; then
        echo "==> firewalld detected"
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ $# -lt 1 ]] && { echo "Usage: $0 <url>"; exit 1; }
    deploy "$@"
fi
