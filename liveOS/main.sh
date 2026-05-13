#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    apply_theme

    cfg_git
    gen_ssh_key
    GPG_PASSPHRASE="lkf.Gpg.mima3" gpg_gen "kefu" "19157521820@163.com"

    ss_local "202.182.112.91"

    install_system_packages
    install_aur_packages

    cryptomator &
    clash-verge &
    keepassxc &

    ok "全部完成"
}

main "$@"
