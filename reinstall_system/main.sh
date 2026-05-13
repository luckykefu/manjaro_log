#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    apply_theme
    sudo_nopassword
    config_mirrors
    sudo pacman -Sy --noconfirm
    enable_fstrim
    set_display_lowest_refresh
    set_timezone
    setup_data_dir

    cfg_git
    gen_ssh_key
    GPG_PASSPHRASE="lkf.Gpg.mima3" gpg_gen "kefu" "19157521820@163.com"

    source_shrc

    ss_local "202.182.112.91"

    install_system_packages
    install_aur_packages

    setup_fcitx5
    install_fonts
    auto_start
    update
}

main "$@"
