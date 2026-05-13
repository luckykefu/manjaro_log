#!/usr/bin/env bash
set -euo pipefail

install_system_packages() {
    sudo pacman -S --needed --noconfirm base-devel yay keepassxc rust zed opencode
}
