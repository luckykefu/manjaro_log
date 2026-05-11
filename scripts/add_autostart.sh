#!/usr/bin/env bash
set -euo pipefail

add_autostart() {
    # 为指定应用创建 ~/.config/autostart/*.desktop 开机自启条目
    # $1: app 应用名（需在 PATH 中）
    local app="$1"
    local autostart_dir="${HOME}/.config/autostart"
    mkdir -p "${autostart_dir}"

    local exec_path=$(which "${app}" 2>/dev/null || echo "")  # 查找可执行路径

    if [[ -n "${exec_path}" ]]; then
        cat > "${autostart_dir}/${app}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${app}
Exec=${exec_path}
Icon=${app}
Comment=Auto-start ${app}
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
EOF
        echo "✓ Created autostart for ${app}"
    else
        echo "✗ Failed to find ${app}" >&2
        return 1
    fi
}

add_autostart "cryptomator" || true   # 加密文件管理
add_autostart "keepassxc" || true     # 密码管理器
add_autostart "clash-verge" || true   # 代理客户端
