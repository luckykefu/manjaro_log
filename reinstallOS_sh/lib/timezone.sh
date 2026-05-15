#!/usr/bin/env bash

## Set timezone from backup config
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_timezone() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local timezone_file="$CONFIG_DIR/timezone"
    if [[ -f "$timezone_file" ]]; then
        local tz
        tz="$(cat "$timezone_file")"
        sudo timedatectl set-timezone "$tz"
        log_success "Timezone set to $tz"
    else
        log_warn "Timezone file not found: $timezone_file"
    fi
}
