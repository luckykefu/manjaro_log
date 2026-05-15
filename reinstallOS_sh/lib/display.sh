#!/usr/bin/env bash

## Copy display configuration files
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_display() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local display_src="$CONFIG_DIR/display"
    if [[ -d "$display_src" ]]; then
        cp -r "$display_src"/* "$HOME_DIR/"
        log_success "Display config files applied from $display_src"
    else
        log_warn "Display config directory not found: $display_src"
    fi
}
