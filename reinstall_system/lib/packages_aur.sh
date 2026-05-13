#!/usr/bin/env bash
set -euo pipefail

install_aur_packages() {
    yay -S --needed --noconfirm clash-verge-rev-bin cryptomator-bin
    echo "clash-verge subscribe link: https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825"
}
