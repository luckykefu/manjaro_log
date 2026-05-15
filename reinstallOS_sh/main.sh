#!/usr/bin/env bash
# # if re-run
#
set -euox pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

reinstall_os() {
    # echo "dark theme"
    # lookandfeeltool -a org.manjaro.breath-dark.desktop --resetLayout
    # sudo_nopassword
    # echo "setting China mirrors" && sudo pacman-mirrors -c China && sudo pacman -Sy --noconfirm
    # echo "enabling fstrim timer" && sudo systemctl enable fstrim.timer
    # timezone
    # chown_dir
    # ssh_keygen

    # gpg_cfg

    git_cfg

    # if [[ "$mode" == "all" || "$mode" == "zshrc" ]]; then
    #     zshrc
    # fi

    # if [[ "$mode" == "all" || "$mode" == "packages" ]]; then
    #     packages
    # fi

    # if [[ "$mode" == "all" || "$mode" == "aur" ]]; then
    #     aur
    # fi

    # if [[ "$mode" == "all" || "$mode" == "fcitx5" ]]; then
    #     fcitx5
    # fi

    # if [[ "$mode" == "all" || "$mode" == "autostart" ]]; then
    #     autostart fcitx5
    # fi

    # if [[ "$mode" == "all" || "$mode" == "display" ]]; then
    #     display 1 60
    # fi

    # if [[ "$mode" == "all" || "$mode" == "update" ]]; then
    #     update
    # fi

    # if [[ "$mode" == "all" || "$mode" == "pacman_cfg" ]]; then
    #     pacman_cfg
    # fi

    # if [[ "$mode" == "all" || "$mode" == "shadowsocks" ]]; then
    #     :
    # fi

    echo "done"
}

main() {
    reinstall_os "$@"
}

main "$@"
