#!/usr/bin/env bash

## Copy pacman.conf from backup
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_pacman_cfg() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local pacman_conf_src="$CONFIG_DIR/pacman.conf"
    if [[ -f "$pacman_conf_src" ]]; then
        sudo cp "$pacman_conf_src" /etc/pacman.conf
        log_success "pacman.conf applied from $pacman_conf_src"
    else
        log_warn "pacman.conf not found: $pacman_conf_src"
    fi
}
