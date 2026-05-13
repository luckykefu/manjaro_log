#!/usr/bin/env bash

ensure_cmd() {
    local cmd=$1
    command -v "$cmd" &>/dev/null || { echo "error: $cmd not found"; return 1; }
}

install_theme() {
    ensure_cmd git
    local git_url="$1"
    local themes_dir="${2:-${HOME}/Downloads/.themes}"
    local theme_name
    theme_name=$(basename "${git_url}" .git)

    mkdir -p "${themes_dir}"
    cd "${themes_dir}"

    git clone "${git_url}" &>/dev/null
    cd "${theme_name}"
    [[ "${theme_name}" == "WhiteSur-cursors" && -f "build.sh" ]] && bash build.sh &>/dev/null || true
    [[ -f "install.sh" ]] && bash install.sh &>/dev/null || true

    rm -rf "${themes_dir}"
}

install_mac_themes() {
    for url in \
        https://github.com/vinceliuice/WhiteSur-icon-theme.git \
        https://github.com/vinceliuice/WhiteSur-kde.git \
        https://github.com/vinceliuice/WhiteSur-cursors.git; do
        install_theme "${url}"
    done
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && install_mac_themes
