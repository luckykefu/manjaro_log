#!/usr/bin/env bash

## Copy shadowsocks config and enable its service
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_shadowsocks() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local ss_src="$CONFIG_DIR/shadowsocks"
    if [[ -d "$ss_src" ]]; then
        sudo mkdir -p /etc/shadowsocks
        sudo cp -r "$ss_src"/* /etc/shadowsocks/
        log_success "Shadowsocks config copied from $ss_src"
    else
        log_warn "Shadowsocks config directory not found: $ss_src"
    fi
    sudo systemctl enable shadowsocks
    sudo systemctl start shadowsocks
    log_success "Shadowsocks service enabled and started"
}
