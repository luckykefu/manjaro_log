#!/usr/bin/env bash
set -euo pipefail

ensure_cmd() {
    local cmd=$1
    command -v "$cmd" &>/dev/null || { echo "error: $cmd not found"; return 1; }
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    ALL_PROXY=socks5://127.0.0.1:1080 install_mac_themes
    kcmshell6 kcm_lookandfeel
    config_kde_clock
    config_kde_wallpaper
    cfg_kde
}

main "$@"
