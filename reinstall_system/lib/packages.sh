#!/usr/bin/env bash
# packages.sh — 统一包安装入口，按类别安装系统/AUR 包
# 用法:
#   install_system_packages         # 基础系统包（base-devel, yay, keepassxc...）
#   install_aur_packages            # AUR 包（clash-verge-rev-bin, cryptomator-bin）
#   install_fonts                   # 中英文等宽字体
#   install_fcitx5_pkgs             # Fcitx5 输入法包
#   install_rust_tools [pkg...]     # Rust CLI 工具（默认: bat, fd, ripgrep...）
#
# 示例:
#   install_system_packages
#   install_rust_tools bat fd rg

pacman_install() {
    ensure_cmd pacman
}
yay_install() {
    ensure_cmd yay
    yay -S --needed --noconfirm "$@"
}



install_fcitx5_pkgs() {
    pacman_install
}

install_rust_tools() {
    local tools=()
    [[ $# -gt 0 ]] && tools=("$@")

    echo "=== Installing Rust CLI tools via pacman ==="
    pacman_install "${tools[@]}"
    echo "=== Done ==="
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Source this file to use its functions"
fi
