#!/usr/bin/env bash

## Copy SSH keys and enable sshd service
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_ssh() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local ssh_src="$CONFIG_DIR/.ssh"
    if [[ -d "$ssh_src" ]]; then
        cp -r "$ssh_src" "$HOME_DIR/"
        chmod 700 "$HOME_DIR/.ssh"
        chmod 600 "$HOME_DIR/.ssh/"*
        log_success "SSH keys copied from $ssh_src"
    else
        log_warn "SSH directory not found: $ssh_src"
    fi
    sudo systemctl enable sshd
    sudo systemctl start sshd
    log_success "sshd service enabled and started"
}
