#!/usr/bin/env bash

## Copy .zshrc from backup
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_zshrc() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local zshrc_src="$CONFIG_DIR/.zshrc"
    if [[ -f "$zshrc_src" ]]; then
        cp "$zshrc_src" "$HOME_DIR/.zshrc"
        log_success ".zshrc copied from $zshrc_src"
    else
        log_warn ".zshrc file not found: $zshrc_src"
    fi
}
