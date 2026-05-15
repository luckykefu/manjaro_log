#!/usr/bin/env bash

## Run a full system update with pacman
## Args: none
cmd_update() {
    log_info "Running full system update..."
    sudo pacman -Syyu --noconfirm
    log_success "System updated"
}
