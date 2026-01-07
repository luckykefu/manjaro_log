#!/bin/bash
# ============================================================================
# Script: wallpaper_conf.sh
# Description: Configure KDE Plasma wallpaper and panel settings
# Logic: Parses plasma-org.kde.plasma.desktop-appletsrc to find containments,
#        sets Bing Picture of the Day wallpaper, configures clock to show seconds,
#        sets up bottom panel launchers for common applications
# ============================================================================
# 脚本: wallpaper_conf.sh
# 描述: 配置 KDE Plasma 壁纸和面板设置
# 逻辑: 解析 plasma-org.kde.plasma.desktop-appletsrc 查找容器，
#        设置必应每日图片壁纸，配置时钟显示秒，为常用应用设置底部面板启动器
# ============================================================================

set -euo pipefail

#--> Configure wallpaper and panels --> 配置壁纸和面板
wallpaper_conf() {
    local config_file="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    
    #--> Get all containment IDs --> 获取所有容器 ID
    local containments=$(grep -oP '^\[Containments\]\[\K\d+(?=\])' "$config_file" | sort -u)
    
    for s in $containments; do
        local plugin=$(kreadconfig6 --file "$config_file" --group "Containments" --group "$s" --key "plugin")
        local lastScreen=$(kreadconfig6 --file "$config_file" --group "Containments" --group "$s" --key "lastScreen")
        local location=$(kreadconfig6 --file "$config_file" --group "Containments" --group "$s" --key "location")
        
        #--> Configure desktop wallpaper --> 配置桌面壁纸
        if [[ "$plugin" == "org.kde.plasma.folder" && "$lastScreen" == "0" ]]; then
            echo " configuring desktop wallpaper"
            kwriteconfig6 --file "$config_file" --group "Containments" --group "$s" --key "wallpaperplugin" "org.kde.potd"
            kwriteconfig6 --file "$config_file" --group "Containments" --group "$s" --group "Wallpaper" --group "org.kde.potd" --group "General" --key "Provider" "bing"
        fi
        
        #--> Configure top panel clock --> 配置顶部面板时钟
        if [[ "$plugin" == "org.kde.panel" && "$location" == "3" ]]; then
            echo " configuring top panel clock"
            local applet_order=$(kreadconfig6 --file "$config_file" --group "Containments" --group "$s" --group "General" --key "AppletOrder")
            local clock_id=$(echo "${applet_order#*=}" | tr ';' '\n' | tail -2 | head -1)
            kwriteconfig6 --file "$config_file" --group "Containments" --group "$s" --group "Applets" --group "$clock_id" --group "Configuration" --group "Appearance" --key "showSeconds" "2"
        fi
        
        #--> Configure bottom panel launchers --> 配置底部面板启动器
        if [[ "$plugin" == "org.kde.panel" && "$location" == "4" ]]; then
            echo " configuring bottom panel launchers"
            local applet_order=$(kreadconfig6 --file "$config_file" --group "Containments" --group "$s" --group "General" --key "AppletOrder")
            local launchers="preferred://filemanager,applications:systemsettings.desktop,applications:org.keepassxc.KeePassXC.desktop,applications:org.cryptomator.Cryptomator.desktop,applications:org.kde.konsole.desktop,applications:code.desktop,applications:google-chrome.desktop,applications:firefox.desktop,applications:Clash Verge.desktop"
            kwriteconfig6 --file "$config_file" --group "Containments" --group "$s" --group "Applets" --group "$applet_order" --group "Configuration" --group "General" --key "launchers" "$launchers"
            # kreadconfig6 --file "$config_file" --group "Containments" --group "$s" --group "Applets" --group "$applet_order" --group "Configuration" --group "General" --key "launchers"
        fi
    done
    
    echo "  ✓ Wallpaper and panel configuration complete"
}
