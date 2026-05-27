#! /usr/bin/env bash
# theme.sh — 安装并应用 WhiteSur KDE 主题/图标/光标
# ========================================================
# 入参说明
# | 环境变量       | 默认值                          | 说明     |
# |----------------|---------------------------------|----------|
# | THEME_PROXY    | socks5://127.0.0.1:1080        | 克隆代理 |
# |                |                                 |          |
# | 返回 0         | 全部成功                        |          |
# | 返回 1         | 有失败项                        |          |
# ========================================================
# 处理逻辑:
#
# cd 到脚本目录
#   └─ for entry in [WhiteSur-kde, WhiteSur-icon-theme, WhiteSur-cursors]
#        ├─ installed()?
#        │    ├─ 是 → 切换主题/光标
#        │    └─ 否 → clone + install → 切换主题/光标

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
THEME_PROXY="${THEME_PROXY:-socks5://127.0.0.1:1080}"

clone() {
    local d="$1" url="$2"
    [[ -d "$d" ]] && return 0
    ALL_PROXY="$THEME_PROXY" git clone --depth 1 "$url" "$d" 2>/dev/null || git clone --depth 1 "$url" "$d"
}

installed() {
    case "$1" in
        WhiteSur-kde)        lookandfeeltool -l 2>/dev/null | grep -qi "WhiteSur" ;;
        WhiteSur-icon-theme) [[ -f /usr/share/icons/WhiteSur/index.theme || -f "$HOME/.local/share/icons/WhiteSur/index.theme" ]] ;;
        WhiteSur-cursors)    plasma-apply-cursortheme --list-themes 2>/dev/null | grep -q "WhiteSur-cursors" ;;
    esac
}

apply_entry() {
    case "$1" in
        WhiteSur-kde)
            local name
            name=$(lookandfeeltool -l 2>/dev/null | grep -i "WhiteSur-dark")
            [[ -n "$name" ]] && lookandfeeltool -a "$name" --resetLayout
            ;;
        WhiteSur-cursors)
            plasma-apply-cursortheme WhiteSur-cursors 2>/dev/null || true
            ;;
    esac
}

install_mac_themes() {
    local fail=0
    for entry in WhiteSur-kde WhiteSur-icon-theme WhiteSur-cursors; do
        if installed "$entry"; then
            apply_entry "$entry"
        else
            clone "$entry" "https://github.com/vinceliuice/$entry" || { ((fail++)); continue; }
            (cd "$entry" && bash ./install.sh) || { ((fail++)); continue; }
            apply_entry "$entry"
        fi
    done
    (( fail == 0 )) || return 1
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && install_mac_themes
