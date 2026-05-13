#!/usr/bin/env bash
# packages.sh — liveOS 统一包安装入口
# 从 reinstall_system 继承通用函数，覆盖 liveOS 特有包列表
# 用法:
#   install_system_packages         # liveOS: keepassxc rust
#   install_aur_packages            # liveOS: cryptomator-bin clash-verge-rev-bin（走代理）

REINSTALL_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../reinstall_system/lib"
source "${REINSTALL_PKG_DIR}/packages.sh"

install_system_packages() {
    pacman_install keepassxc rust
}

install_aur_packages() {
    ALL_PROXY=socks5://127.0.0.1:1080 yay_install cryptomator-bin clash-verge-rev-bin
}