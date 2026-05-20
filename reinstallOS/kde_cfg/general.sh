#!/bin/bash
# 通用 KDE 配置(字体/输入/KWin/KRunner/锁屏/活动)

FIXED_FONT="Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
TITLE_FONT="Source Han Sans CN,10,-1,5,316,0,0,0,0,0,0,0,0,0,0,1,Normal"

kwrite() {
    kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"
}

kwrite_int() {
    kwriteconfig6 --file "$1" --group "$2" --key "$3" --type int "$4"
}

kwrite_bool() {
    kwriteconfig6 --file "$1" --group "$2" --key "$3" --type bool "$4"
}

config_fonts() {
    echo "[INFO] 配置字体 ..."
    kwrite kdeglobals General font "$TITLE_FONT"
    kwrite kdeglobals General menuFont "$FIXED_FONT"
    kwrite kdeglobals General smallestReadableFont "Source Han Sans CN,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwrite kdeglobals General toolBarFont "$FIXED_FONT"
    kwrite kdeglobals General fixed "$FIXED_FONT"
    kwrite kdeglobals WM activeFont "$TITLE_FONT"
    echo "[INFO] 字体已配置"
}

config_input() {
    echo "[INFO] 配置输入设备 ..."
    kwriteconfig6 --file kcminputrc --group Libinput \
        --group 4152 --group 5898 \
        --group "SteelSeries SteelSeries Rival 100 Dell China" \
        --key PointerAcceleration 1
    kwrite kcminputrc Keyboard NumLock 0
    echo "[INFO] 输入设备已配置"
}

config_kwin() {
    echo "[INFO] 配置 KWin ..."
    kwrite kwinrc Effect-overview BorderActivate "1,7"
    kwrite kwinrc ElectricBorders BottomLeft KRunner
    kwrite kwinrc ElectricBorders TopLeft ApplicationLauncher
    kwrite kwinrc TabBox LayoutName big_icons

    local -A plugins
    plugins[mouseclickEnabled]=true
    plugins[trackmouseEnabled]=true
    plugins[contrastEnabled]=true
    plugins[blurEnabled]=true
    plugins[fallapartEnabled]=false
    plugins[mousemarkEnabled]=true
    plugins[translucencyEnabled]=true
    plugins[wobblywindowsEnabled]=true
    plugins[magiclampEnabled]=true
    plugins[squashEnabled]=false
    plugins[diminactiveEnabled]=true
    plugins[glideEnabled]=true
    plugins[scaleEnabled]=false

    for key in "${!plugins[@]}"; do
        kwriteconfig6 --file kwinrc --group Plugins --key "$key" "${plugins[$key]}"
    done
    echo "[INFO] KWin 已配置"
}

config_screenlocker() {
    echo "[INFO] 配置锁屏 ..."
    kwrite kscreenlockerrc Daemon Timeout 0
    kwrite kscreenlockerrc Daemon LockGrace 900
    kwrite kscreenlockerrc Daemon RequirePassword false
    kwrite kscreenlockerrc Daemon Autolock false
    echo "[INFO] 锁屏已配置"
}

config_activities() {
    echo "[INFO] 配置活动管理 ..."
    kwriteconfig6 --file kactivitymanagerd-pluginsrc \
        --group Plugin-org.kde.ActivityManager.Resources.Scoring \
        --key keep-history-for 1
    echo "[INFO] 活动管理已配置"
}

config_krunner() {
    echo "[INFO] 配置 KRunner ..."
    kwrite_bool krunnerrc General FreeFloating true
    echo "[INFO] KRunner 已配置"
}

config_kde_general() {
    echo "[INFO] 通用 KDE 配置 ..."
    config_fonts
    config_input
    config_kwin
    config_screenlocker
    config_activities
    config_krunner
    echo "[INFO] 通用 KDE 配置完成"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && { config_kde_general; }
