#!/usr/bin/env bash
set -euo pipefail

auto_start() {
    local AUTOSTART_DIR="${HOME}/.config/autostart"
    local APPLICATIONS_DIR="/usr/share/applications"
    local bins=(cryptomator clash-verge keepassxc)

    mkdir -p "${AUTOSTART_DIR}"
    for bin in "${bins[@]}"; do
        local path
        path=$(which "${bin}" 2>/dev/null) || { echo "[-] ${bin}: not found, skip"; continue; }
        echo "[+] ${bin}: found at ${path}"
        local desktop_file="${APPLICATIONS_DIR}/${bin}.desktop"
        local target="${AUTOSTART_DIR}/${bin}.desktop"
        if [[ -f "${desktop_file}" ]]; then
            cp "${desktop_file}" "${target}"
            echo "    -> copied from ${desktop_file}"
        else
            cat > "${target}" <<EOF
[Desktop Entry]
Type=Application
Name=${bin}
Exec=${path}
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
            echo "    -> created minimal desktop entry"
        fi
        chmod 644 "${target}"
    done
    echo "[✓] done"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && auto_start