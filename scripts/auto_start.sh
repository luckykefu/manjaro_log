#!/usr/bin/env bash
set -euo pipefail
AUTOSTART_DIR="${HOME}/.config/autostart"
APPLICATIONS_DIR="/usr/share/applications"
bins=(
    cryptomator
    clash-verge
    keepassxc
)
mkdir -p "${AUTOSTART_DIR}"
for bin in "${bins[@]}"; do
    if ! path=$(which "${bin}" 2>/dev/null); then
        echo "[-] ${bin}: not found, skip"
        continue
    fi
    echo "[+] ${bin}: found at ${path}"
    desktop_file="${APPLICATIONS_DIR}/${bin}.desktop"
    target="${AUTOSTART_DIR}/${bin}.desktop"
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
