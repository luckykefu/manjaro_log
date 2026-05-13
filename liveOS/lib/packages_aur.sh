#!/usr/bin/env bash
set -euo pipefail

install_aur_packages() {
    ALL_PROXY=socks5://127.0.0.1:1080 yay -S --needed --noconfirm cryptomator-bin clash-verge-rev-bin
}
