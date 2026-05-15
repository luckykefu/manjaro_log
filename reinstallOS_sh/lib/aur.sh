#!/usr/bin/env bash

## Install AUR helper (yay) via git clone and makepkg
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_aur() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    if command -v yay &>/dev/null; then
        log_info "yay is already installed"
        return 0
    fi
    local tmpdir
    tmpdir="$(mktemp -d)"
    run_cmd git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    log_success "yay installed"
}
