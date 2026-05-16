#!/usr/bin/env bash
# # if re-run
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

reinstall_os() {
    echo "dark theme"
    lookandfeeltool -a org.manjaro.breath-dark.desktop --resetLayout
    display 1 60
    sudo_nopassword
    echo "setting China mirrors" && sudo pacman-mirrors -c China && sudo pacman -Sy --noconfirm
    pacman_cfg
    echo "enabling fstrim timer" && sudo systemctl enable fstrim.timer
    timezone
    chown_dir
    ssh_keygen
    gpg_cfg
    git_cfg
    zshrc
    packages
    curl -fsSL https://opencode.ai/install | bash
    fcitx5
    update
}

main() {
    reinstall_os "$@"
}

main "$@"
