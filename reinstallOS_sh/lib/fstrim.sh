#!/usr/bin/env bash

## Enable and start fstrim timer
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_fstrim() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    sudo systemctl enable fstrim.timer
    sudo systemctl start fstrim.timer
    log_success "fstrim timer enabled and started"
}
