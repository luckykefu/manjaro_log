#!/usr/bin/env bash
set -euo pipefail

config_kde_wallpaper() {
    local config_file="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"
    
    # 检查配置文件
    [[ ! -f "${config_file}" ]] && { echo "✗ 配置文件不存在" >&2; return 1; }
    
    # 查找桌面容器
    local found=0
    grep -oP '^\[Containments\]\[\K\d+(?=\])' "${config_file}" | sort -u | while read -r c_id; do
        local location=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "location")
        local plugin=$(kreadconfig6 --file "${config_file}" --group "Containments" --group "${c_id}" --key "plugin")
        
        if [[ "${location}" == "0" && "${plugin}" == "org.kde.plasma.folder" ]]; then
            echo "→ 找到桌面容器: Containment=${c_id}"
            
            # 设置壁纸插件为 org.kde.potd
            kwriteconfig6 --file "${config_file}" \
                --group "Containments" --group "${c_id}" \
                --key "wallpaperplugin" "org.kde.potd"
            
            # 配置 Bing 每日壁纸
            kwriteconfig6 --file "${config_file}" \
                --group "Containments" --group "${c_id}" \
                --group "Wallpaper" --group "org.kde.potd" --group "General" \
                --key "Provider" "bing"
            
            echo "✓ 已配置 Bing 每日壁纸"
            found=1
        fi
    done
    
    [[ ${found} -eq 0 ]] && echo "⚠ 未找到桌面容器"
    
    # 重启 Plasma 使配置生效
    echo "→ 重启 Plasma Shell..."
    kquitapp6 plasmashell && kstart plasmashell &>/dev/null &
    echo "✓ 配置完成"
}

config_kde_wallpaper
