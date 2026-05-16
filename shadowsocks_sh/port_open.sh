#! /usr/bin/env bash
set -euo pipefail

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    port_open "$@"
fi
