#!/usr/bin/env bash

## Chown home directory to current user
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_chown() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local user
    user="$(id -un)"
    sudo chown -R "$user":"$user" "$HOME_DIR"
    log_success "Chowned $HOME_DIR to $user"
}
