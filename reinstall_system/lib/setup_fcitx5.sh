#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/packages.sh"

setup_fcitx5() {

    kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop

    rm_or_skip "$HOME/.config/fcitx5" delete
    cp -r "${SCRIPT_DIR}/fcitx5" "$HOME/.config/fcitx5"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_fcitx5
fi
