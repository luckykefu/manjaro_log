#!/usr/bin/env bash

## Copy fcitx5 configuration directory
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_fcitx5() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local fcitx5_src="$CONFIG_DIR/.config/fcitx5"
    if [[ -d "$fcitx5_src" ]]; then
        mkdir -p "$HOME_DIR/.config"
        cp -r "$fcitx5_src" "$HOME_DIR/.config/"
        log_success "fcitx5 config applied from $fcitx5_src"
    else
        log_warn "fcitx5 config directory not found: $fcitx5_src"
    fi
}
