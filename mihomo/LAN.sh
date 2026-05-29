#! /usr/bin/env bash
set -euo pipefail
port_open() {
    local p=$(yq -r '.mixed-port // 7890' config.yaml)
    p=${p:-7890}
    type firewall-cmd &>/dev/null && sudo firewall-cmd --add-port=$p/tcp --permanent --reload 2>/dev/null || :
    type ufw &>/dev/null && sudo ufw allow $p/tcp 2>/dev/null || :
    type iptables &>/dev/null && { sudo iptables -C INPUT -p tcp --dport $p -j ACCEPT 2>/dev/null || sudo iptables -A INPUT -p tcp --dport $p -j ACCEPT; } || :
}
port_open
