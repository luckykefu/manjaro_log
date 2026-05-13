#!/usr/bin/env bash
set -euo pipefail

install_wg() {
    command -v wg &>/dev/null && return
    warn "安装 WireGuard..."
    if command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm wireguard-tools
    elif command -v apt &>/dev/null; then
        apt update -y && apt install -y wireguard
    elif command -v dnf &>/dev/null; then
        dnf install -y wireguard-tools
    elif command -v brew &>/dev/null; then
        brew install wireguard-tools
    else
        err "请手动安装 WireGuard"
        return 1
    fi
}
