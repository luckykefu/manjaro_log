#!/usr/bin/env bash

ensure_cmd() {
    local cmd=$1
    command -v "$cmd" &>/dev/null || { echo "error: $cmd not found"; return 1; }
}

config_kde_clock() {
    ensure_cmd kwriteconfig6
    ensure_cmd kreadconfig6
    local config_file="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

    while IFS= read -r line; do
        if [[ "${line}" =~ ^\[Containments\]\[([0-9]+)\]\[Applets\]\[([0-9]+)\]$ ]]; then
            local containment_id="${BASH_REMATCH[1]}"
            local applet_id="${BASH_REMATCH[2]}"
            local plugin
            plugin=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${containment_id}" --group "Applets" --group "${applet_id}" --key "plugin")

            if [[ "${plugin}" == "org.kde.plasma.digitalclock" ]]; then
                kwriteconfig6 --file "${config_file}" --group "Containments" --group "${containment_id}" --group "Applets" --group "${applet_id}" --group "Configuration" --group "Appearance" --key "showSeconds" "Always"
                kwriteconfig6 --file "${config_file}" --group "Containments" --group "${containment_id}" --group "Applets" --group "${applet_id}" --group "Configuration" --group "Appearance" --key "use24hFormat" "2"
            fi
        fi
    done < "${config_file}"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && config_kde_clock
