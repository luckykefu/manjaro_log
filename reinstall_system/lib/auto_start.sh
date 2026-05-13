#!/usr/bin/env bash
# auto_start.sh — 配置开机自启应用
# 用法: auto_start [app1 app2 ...]

auto_start() {
    local -a bins=()
    if [[ $# -eq 0 ]]; then
        bins=(cryptomator clash-verge keepassxc)
    else
        bins=("$@")
    fi

    mkdir -p "${HOME}/.config/autostart"

    # 1. 为每个应用创建 .desktop 自启条目
    for bin in "${bins[@]}"; do
        local path target
        path=$(command -v "$bin") || { echo "skip: $bin not found"; continue; }
        target="${HOME}/.config/autostart/${bin}.desktop"

        if [[ -f "/usr/share/applications/${bin}.desktop" ]]; then
            cp "/usr/share/applications/${bin}.desktop" "$target"
        else
            cat > "$target" << EOF
[Desktop Entry]
Type=Application
Name=${bin}
Exec=${path}
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
        fi
        chmod 644 "$target"
        echo "autostart enabled: $bin"
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    auto_start "$@"
fi
