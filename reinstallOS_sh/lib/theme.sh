#!/usr/bin/env bash

## Configure theme from backup
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_theme() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local theme_src="$CONFIG_DIR/theme"
    if [[ -d "$theme_src" ]]; then
        cp -r "$theme_src"/* "$HOME_DIR/"
        log_success "Theme configured from $theme_src"
    else
        log_warn "Theme directory not found: $theme_src"
    fi
}
