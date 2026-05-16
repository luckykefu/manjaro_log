#!/bin/bash
# kde_cfg config
# 从环境变量加载配置,缺失项使用默认值

load_config() {
    local SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    KDE_CFG_PROJECT_ROOT="${KDE_CFG_PROJECT_ROOT:-"$SELF_DIR"}"
    KDE_CFG_PROXY="${KDE_CFG_PROXY:-socks5://127.0.0.1:1080}"
    KDE_CFG_LOOKANDFEEL_THEME="${KDE_CFG_LOOKANDFEEL_THEME:-com.github.vinceliuice.WhiteSur-dark}"
    KDE_CFG_CURSOR_THEME="${KDE_CFG_CURSOR_THEME:-WhiteSur-cursors}"
    KDE_CFG_WHITESUR_KDE_REPO="${KDE_CFG_WHITESUR_KDE_REPO:-https://github.com/vinceliuice/WhiteSur-kde}"
    KDE_CFG_WHITESUR_ICON_REPO="${KDE_CFG_WHITESUR_ICON_REPO:-https://github.com/vinceliuice/WhiteSur-icon-theme}"
    KDE_CFG_WHITESUR_CURSORS_REPO="${KDE_CFG_WHITESUR_CURSORS_REPO:-https://github.com/vinceliuice/WhiteSur-cursors}"
    KDE_CFG_WALLPAPER="${KDE_CFG_WALLPAPER:-}"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && {
    load_config
    declare -p | grep KDE_CFG_
}
