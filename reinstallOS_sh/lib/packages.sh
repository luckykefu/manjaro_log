#!/usr/bin/env bash

## Install package groups via pacman
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_packages() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local pkg_list="$CONFIG_DIR/packages.txt"
    if [[ -f "$pkg_list" ]]; then
        local packages
        packages="$(grep -v '^\s*#' "$pkg_list" | tr '\n' ' ')"
        if [[ -n "$packages" ]]; then
            sudo pacman -S --needed --noconfirm $packages
            log_success "Packages installed from $pkg_list"
        else
            log_warn "No packages to install (list empty or fully commented)"
        fi
    else
        log_warn "Package list not found: $pkg_list"
    fi
}
