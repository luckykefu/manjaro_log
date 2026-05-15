#!/usr/bin/env bash

## Copy autostart desktop entries
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_autostart() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local autostart_src="$CONFIG_DIR/.config/autostart"
    if [[ -d "$autostart_src" ]]; then
        mkdir -p "$HOME_DIR/.config"
        cp -r "$autostart_src" "$HOME_DIR/.config/"
        log_success "Autostart entries applied from $autostart_src"
    else
        log_warn "Autostart directory not found: $autostart_src"
    fi
}
