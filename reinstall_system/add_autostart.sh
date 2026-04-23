#!/usr/bin/env bash
set -euo pipefail

add_autostart() {
    local app="$1"
    local autostart_dir="${HOME}/.config/autostart"
    mkdir -p "${autostart_dir}"
    
    local exec_path=$(which "${app}" 2>/dev/null || echo "")
    
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

# 使用示例
add_autostart "cryptomator"
add_autostart "keepassxc"
add_autostart "clash-verge"
