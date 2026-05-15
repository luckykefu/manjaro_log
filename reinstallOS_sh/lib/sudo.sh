#!/usr/bin/env bash

## Copy sudoers config from backup
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_sudo() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local sudoers_src="$CONFIG_DIR/sudoers"
    if [[ -f "$sudoers_src" ]]; then
        sudo cp "$sudoers_src" /etc/sudoers
        sudo chmod 440 /etc/sudoers
        log_success "sudoers config applied from $sudoers_src"
    else
        log_warn "sudoers file not found: $sudoers_src"
    fi
}
