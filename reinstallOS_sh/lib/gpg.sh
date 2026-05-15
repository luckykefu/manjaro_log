#!/usr/bin/env bash

## Copy and import GPG keys from backup
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_gpg() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local gnupg_src="$CONFIG_DIR/.gnupg"
    if [[ -d "$gnupg_src" ]]; then
        cp -r "$gnupg_src" "$HOME_DIR/"
        chmod 700 "$HOME_DIR/.gnupg"
        find "$HOME_DIR/.gnupg" -type f -exec chmod 600 {} \;
        log_success "GPG directory copied from $gnupg_src"
    else
        log_warn "GPG directory not found: $gnupg_src"
    fi
    local private_key="$CONFIG_DIR/private.key"
    if [[ -f "$private_key" ]]; then
        gpg --import "$private_key"
        log_success "GPG private key imported from $private_key"
    fi
}
