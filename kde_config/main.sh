#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    info "配置 macOS 主题..."
    ALL_PROXY=socks5://127.0.0.1:1080 install_mac_themes

    kcmshell6 kcm_lookandfeel

    config_kde_clock
    config_kde_wallpaper
    cfg_kde

    ok "KDE 配置完成"
}

main "$@"
