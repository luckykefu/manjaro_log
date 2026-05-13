#!/usr/bin/env bash

ensure_cmd() {
    local cmd=$1
    command -v "$cmd" &>/dev/null || { echo "error: $cmd not found"; return 1; }
}

config_kde_wallpaper() {
    ensure_cmd kwriteconfig6
    ensure_cmd kreadconfig6
    local config_file="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

    while read -r c_id; do
        local location plugin
        location=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "location")
        plugin=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "plugin")

        if [[ "${location}" == "0" && "${plugin}" == "org.kde.plasma.folder" ]]; then
            kwriteconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "wallpaperplugin" "org.kde.potd"
            kwriteconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --group "Wallpaper" --group "org.kde.potd" --group "General" --key "Provider" "bing"
        fi
    done < <(grep -oP '^\[Containments\]\[\K\d+(?=\])' "${config_file}" | sort -u)
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && config_kde_wallpaper
