#!/usr/bin/env bash
set -euo pipefail

is_theme_installed() {
    # 检查主题是否已安装，避免重复安装
    # $1: theme_name
    local theme_name="$1"
    case "${theme_name}" in
        WhiteSur-icon-theme)
            [[ -d "${HOME}/.local/share/icons/WhiteSur" ]] || [[ -d "${HOME}/.icons/WhiteSur" ]]
            ;;
        WhiteSur-kde)
            [[ -d "${HOME}/.local/share/plasma/desktoptheme/WhiteSur" ]]
            ;;
        WhiteSur-cursors)
            [[ -d "${HOME}/.local/share/icons/WhiteSur-cursors" ]] || [[ -d "${HOME}/.icons/WhiteSur-cursors" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

install_theme() {
    # clone 主题仓库，执行 install.sh，安装完清理源码
    # $1: git_url, $2: themes_dir (可选)
    local git_url="$1"
    local themes_dir="${2:-${HOME}/Downloads/.themes}"
    local theme_name
    theme_name=$(basename "${git_url}" .git)

    if is_theme_installed "${theme_name}"; then
        echo "✓ ${theme_name} already installed, skipping"
        return 0
    fi

    mkdir -p "${themes_dir}"
    cd "${themes_dir}" || return 1

    local theme_path="${themes_dir}/${theme_name}"

    if [[ ! -d "${theme_path}" ]]; then
        git clone "${git_url}" &>/dev/null && echo "✓ Cloned ${theme_name}"
    fi

    cd "${theme_path}" || return 1

    if [[ "${theme_name}" == "WhiteSur-cursors" && -f "build.sh" ]]; then
        bash build.sh &>/dev/null && echo "✓ Built cursors"  # 光标主题需先编译
    fi

    if [[ -f "install.sh" ]]; then
        bash install.sh && echo "✓ Installed ${theme_name}"
    fi

    rm -rf "${theme_path}" && echo "✓ Cleaned ${theme_name}"  # 安装后清理源码
}

main() {
    command -v git >/dev/null 2>&1 || { echo "✗ git not found" >&2; exit 1; }  # 依赖检查

    local urls="https://github.com/vinceliuice/WhiteSur-icon-theme.git
https://github.com/vinceliuice/WhiteSur-kde.git
https://github.com/vinceliuice/WhiteSur-cursors.git"

    echo "🎨 Installing WhiteSur themes..."
    while IFS= read -r url; do
        url=$(echo "${url}" | xargs)
        [[ -z "${url}" ]] && continue
        install_theme "${url}"
    done <<<"${urls}"

    rm -rf "${HOME}/Downloads/.themes"
    echo "✓ All themes processed"
}

main
