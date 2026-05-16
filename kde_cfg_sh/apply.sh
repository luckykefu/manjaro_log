#!/bin/bash
# 应用 KDE 全局主题和光标

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/config.sh"

apply_lookandfeel() {
    echo "[INFO] 应用全局主题: $KDE_CFG_LOOKANDFEEL_THEME"
    local theme=$(lookandfeeltool -l | grep "WhiteSur-dark")
    lookandfeeltool -a $theme --resetLayout
    $OFFSCREEN plasma-apply-lookandfeel -a "$KDE_CFG_LOOKANDFEEL_THEME"
    echo "[INFO] 全局主题已应用: $KDE_CFG_LOOKANDFEEL_THEME"
}

apply_cursor() {
    echo "[INFO] 设置光标主题: $KDE_CFG_CURSOR_THEME"
    local c_theme=$(plasma-apply-cursortheme --list-themes | grep "WhiteSur-cursors")
    [[ -z c_theme ]] || plasma-apply-cursortheme WhiteSur-cursors
    echo "[INFO] 光标主题已设置: $KDE_CFG_CURSOR_THEME"
}

apply_theme() {
    echo "[INFO] 应用 theme ..."
    apply_lookandfeel
    apply_cursor
    echo "[INFO] theme 已应用"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && { load_config; apply_theme; }
