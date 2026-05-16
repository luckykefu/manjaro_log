#!/bin/bash
# kde_cfg CLI 入口
# 用法: ./kde_cfg.sh [模块]
# 模块: all, theme, apply, clock, wallpaper, general
# 默认: all

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/config.sh"

restart_plasma() {
    echo "[INFO] 重启 plasmashell ..."
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
}

run_all() {
    echo "[INFO] --- 开始全量配置 ---"
    "$SELF_DIR/theme.sh" || true
    "$SELF_DIR/apply.sh" || true
    "$SELF_DIR/general.sh" || true
    restart_plasma
    echo "[INFO] --- 全量配置完成 ---"
}

main() {
    local module="${1:-all}"
    load_config
    echo "[INFO] 开始配置模块 [$module]"

    case "$module" in
        theme)     "$SELF_DIR/theme.sh";;
        apply)     "$SELF_DIR/apply.sh";;
        general)   "$SELF_DIR/general.sh";;
        all)       run_all; return 0;;
        *)         echo "[ERROR] 未知模块: $module. 可选: all, theme, apply, clock, wallpaper, general"; return 1;;
    esac

    restart_plasma
    echo "[INFO] 模块 [$module] 完成"
}
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { main "$@"; }
