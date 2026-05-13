#!/usr/bin/env bash
set -euo pipefail

update() {
    sudo pacman -Syyu --noconfirm
    yay -Syyu --noconfirm
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && update