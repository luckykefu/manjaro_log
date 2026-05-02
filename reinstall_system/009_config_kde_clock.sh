#!/usr/bin/env bash
set -euo pipefail

config_kde_clock() {
    # 配置 KDE 数字时钟显示秒数和24小时制，重启 plasmashell 生效
    local config_file="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

    [[ ! -f "${config_file}" ]] && { echo "✗ 配置文件不存在" >&2; return 1; }

    local found=0
    while IFS= read -r line; do
        if [[ "${line}" =~ ^\[Containments\]\[([0-9]+)\]\[Applets\]\[([0-9]+)\]$ ]]; then
            local containment_id="${BASH_REMATCH[1]}"
            local applet_id="${BASH_REMATCH[2]}"

            local plugin=$(kreadconfig6 --file "${config_file}" \
                --group "Containments" --group "${containment_id}" \
                --group "Applets" --group "${applet_id}" \
                --key "plugin")

            if [[ "${plugin}" == "org.kde.plasma.digitalclock" ]]; then
                echo "→ 找到 digitalclock: Containment=${containment_id}, Applet=${applet_id}"

                kwriteconfig6 --file "${config_file}" \
                    --group "Containments" --group "${containment_id}" \
                    --group "Applets" --group "${applet_id}" \
                    --group "Configuration" --group "Appearance" \
                    --key "showSeconds" "Always"  # 显示秒数

                kwriteconfig6 --file "${config_file}" \
                    --group "Containments" --group "${containment_id}" \
                    --group "Applets" --group "${applet_id}" \
                    --group "Configuration" --group "Appearance" \
                    --key "use24hFormat" "2"  # 24小时制

                echo "✓ 已配置 digitalclock"
                found=1
            fi
        fi
    done < "${config_file}"

    [[ ${found} -eq 0 ]] && echo "⚠ 未找到 digitalclock 插件"

    kquitapp6 plasmashell && kstart plasmashell &>/dev/null &  # 重启 Plasma 生效
    echo "✓ 配置完成"
}

config_kde_clock
