#!/usr/bin/env bash

install_wg() {
    ensure_cmd pacman
    pacman -Sy --noconfirm wireguard-tools
}
