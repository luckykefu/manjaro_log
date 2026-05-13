#!/usr/bin/env bash
set -euo pipefail

apply_theme() {
    info "应用主题..."
    lookandfeeltool -a org.manjaro.breath-dark.desktop
}

config_mirrors() {
    sudo pacman-mirrors -c China
}

enable_fstrim() {
    sudo systemctl enable fstrim.timer
}

set_display_lowest_refresh() {
    local output
    output=$(kscreen-doctor -o | grep -m1 "enabled" | awk '{print $3}')
    local lowest
    lowest=$(kscreen-doctor -o | sed -n "/$output/,/^Output:/p" | \
        grep -oP '\d+:\d+x\d+@\d+' | sort -t@ -k2 -n | head -1 | cut -d: -f1)
    kscreen-doctor "output.${output}.mode.${lowest}"
}

set_timezone() {
    sudo timedatectl set-timezone UTC
    sudo timedatectl set-ntp true
}

setup_data_dir() {
    sudo chown -R "$USER:$USER" /data
}
