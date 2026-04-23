#!/usr/bin/env bash
set -euo pipefail

config_kde_launchers() {
    local config_file="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"
    
    # 检查配置文件
    [[ ! -f "${config_file}" ]] && { echo "✗ 配置文件不存在" >&2; return 1; }
    
    # 启动器列表
    local launchers="preferred://filemanager,applications:systemsettings.desktop,applications:org.keepassxc.KeePassXC.desktop,applications:org.cryptomator.Cryptomator.desktop,applications:org.kde.konsole.desktop,applications:code.desktop,applications:firefox.desktop"
    
    # 查找并配置 icontasks
    local found=0
    while IFS= read -r line; do
        if [[ "${line}" =~ ^\[Containments\]\[([0-9]+)\]\[Applets\]\[([0-9]+)\]$ ]]; then
            local containment_id="${BASH_REMATCH[1]}"
            local applet_id="${BASH_REMATCH[2]}"
            
            # 检查是否为 icontasks 插件
            local plugin=$(kreadconfig6 --file "${config_file}" \
                --group "Containments" --group "${containment_id}" \
                --group "Applets" --group "${applet_id}" \
                --key "plugin")
            
            if [[ "${plugin}" == "org.kde.plasma.icontasks" ]]; then
                echo "→ 找到 icontasks: Containment=${containment_id}, Applet=${applet_id}"
                
                # 配置启动器列表
                kwriteconfig6 --file "${config_file}" \
                    --group "Containments" --group "${containment_id}" \
                    --group "Applets" --group "${applet_id}" \
                    --group "Configuration" --group "General" \
                    --key "launchers" "${launchers}"
                
                echo "✓ 已配置 icontasks 启动器"
                found=1
            fi
        fi
    done < "${config_file}"
    
    [[ ${found} -eq 0 ]] && echo "⚠ 未找到 icontasks 插件"
    
    # 重启 Plasma 使配置生效
    echo "→ 重启 Plasma Shell..."
    kquitapp6 plasmashell && kstart plasmashell &>/dev/null &
    echo "✓ 配置完成"
}

config_kde_launchers
