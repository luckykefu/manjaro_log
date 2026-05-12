#!/usr/bin/env bash
set -euo pipefail

config_kde_wallpaper() {
    # 设置 KDE 桌面壁纸为 Bing 每日壁纸（org.kde.potd）
    local config_file="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

    [[ ! -f "${config_file}" ]] && { echo "✗ 配置文件不存在" >&2; return 1; }

    local found=0
    while read -r c_id; do
        local location=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "location")
        local plugin=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "plugin")

        if [[ "${location}" == "0" && "${plugin}" == "org.kde.plasma.folder" ]]; then  # location=0 为桌面容器
            echo "→ 找到桌面容器: Containment=${c_id}"

            kwriteconfig6 --file "${config_file}" \
                --group "Containments" --group "${c_id}" \
                --key "wallpaperplugin" "org.kde.potd"  # 每日一图插件

            kwriteconfig6 --file "${config_file}" \
                --group "Containments" --group "${c_id}" \
                --group "Wallpaper" --group "org.kde.potd" --group "General" \
                --key "Provider" "bing"  # 使用 Bing 图源

            echo "✓ 已配置 Bing 每日壁纸"
            found=1
        fi
    done < <(grep -oP '^\[Containments\]\[\K\d+(?=\])' "${config_file}" | sort -u)

    [[ ${found} -eq 0 ]] && echo "⚠ 未找到桌面容器"

    echo "✓ 配置完成"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && config_kde_wallpaper
