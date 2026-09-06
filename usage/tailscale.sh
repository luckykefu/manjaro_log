%%bash
#!/usr/bin/env bash
set -euo pipefail

TS_AUTHKEY="tskey-auth-kLLnbWoPCV11CNTRL-GJ2u4M73hq4Cacyu84NUq4S6fHe7EQZv"

check_env() {
    local pid1
    pid1=$(ps --pid 1 -o comm= 2>/dev/null || echo "unknown")
    [[ $pid1 == systemd ]] && { echo "tun"; return; }
    echo "userspace"
}

start_userspace() {
    echo "starting tailscaled (userspace-networking)..."
    sudo killall tailscaled 2>/dev/null || true
    nohup sudo tailscaled --tun=userspace-networking \
        --state=/var/lib/tailscale/tailscaled.state \
        > /tmp/tailscaled.log 2>&1 &
    sleep 2
    sudo tailscale --socket=/run/tailscale/tailscaled.sock up \
        --accept-routes --accept-dns=false \
        --ssh --authkey="${TS_AUTHKEY}"
}

start_systemd() {
    echo "starting tailscaled (systemd)..."
    sudo systemctl enable --now tailscaled
    sudo tailscale up --accept-routes --accept-dns=false \
        --ssh --authkey="${TS_AUTHKEY}"
}

main() {
    install
    local mode
    mode=$(check_env)
    echo "mode: $mode"
    [[ $mode == tun ]] && start_systemd || start_userspace
    echo "done, ip: $(tailscale ip -4)"
}

main
