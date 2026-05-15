#!/usr/bin/env bash

## Configure pacman mirrorlist from backup
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_mirrors() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local mirrorlist_src="$CONFIG_DIR/mirrorlist"
    if [[ -f "$mirrorlist_src" ]]; then
        sudo cp "$mirrorlist_src" /etc/pacman.d/mirrorlist
        log_success "Mirrorlist applied from $mirrorlist_src"
    else
        log_warn "Mirrorlist file not found: $mirrorlist_src"
    fi
}
