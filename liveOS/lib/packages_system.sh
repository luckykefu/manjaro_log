#!/usr/bin/env bash
set -euo pipefail

install_system_packages() {
    sudo pacman -Sy --needed --noconfirm keepassxc rust
}
