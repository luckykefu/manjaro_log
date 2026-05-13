#!/usr/bin/env bash

ensure_cmd() {
    local cmd=$1
    command -v "$cmd" &>/dev/null || { echo "error: $cmd not found"; return 1; }
}

cfg_kde() {
    ensure_cmd kwriteconfig6
    local cf

    cf="$HOME/.config/kdeglobals"
    kwriteconfig6 --file "$cf" --group "General" --key "font" "Source Han Sans CN,10,-1,5,316,0,0,0,0,0,0,0,0,0,0,1,Normal"
    kwriteconfig6 --file "$cf" --group "General" --key "menuFont" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$cf" --group "General" --key "smallestReadableFont" "Source Han Sans CN,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$cf" --group "General" --key "toolBarFont" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$cf" --group "General" --key "fixed" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$cf" --group "WM" --key "activeFont" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    cf="$HOME/.config/kcminputrc"
    kwriteconfig6 --file "$cf" --group "Libinput" --group "4152" --group "5898" --group "SteelSeries SteelSeries Rival 100 Dell China" --key "PointerAcceleration" "1"
    kwriteconfig6 --file "$cf" --group "Keyboard" --key "NumLock" "0"

    cf="$HOME/.config/kwinrc"
    kwriteconfig6 --file "$cf" --group "Effect-overview" --key "BorderActivate" "1,7"
    kwriteconfig6 --file "$cf" --group "ElectricBorders" --key "BottomLeft" "KRunner"
    kwriteconfig6 --file "$cf" --group "ElectricBorders" --key "TopLeft" "ApplicationLauncher"
    kwriteconfig6 --file "$cf" --group "TabBox" --key "LayoutName" "big_icons"
    kwriteconfig6 --file "$cf" --group "General" --key "FreeFloating" --type bool true
    kwriteconfig6 --file "$cf" --group "General" --key "historyBehavior" "ImmediateCompletion"
    kwriteconfig6 --file "$cf" --group "Plugins" --key "mouseclickEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "trackmouseEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "contrastEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "blurEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "fallapartEnabled" --type bool false
    kwriteconfig6 --file "$cf" --group "Plugins" --key "mousemarkEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "translucencyEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "wobblywindowsEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "magiclampEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "squashEnabled" --type bool false
    kwriteconfig6 --file "$cf" --group "Plugins" --key "diminactiveEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "glideEnabled" --type bool true
    kwriteconfig6 --file "$cf" --group "Plugins" --key "scaleEnabled" --type bool false

    cf="$HOME/.config/kscreenlockerrc"
    kwriteconfig6 --file "$cf" --group "Daemon" --key "Timeout" "0"
    kwriteconfig6 --file "$cf" --group "Daemon" --key "LockGrace" "900"
    kwriteconfig6 --file "$cf" --group "Daemon" --key "RequirePassword" "false"
    kwriteconfig6 --file "$cf" --group "Daemon" --key "Autolock" "false"

    cf="$HOME/.config/kactivitymanagerd-pluginsrc"
    kwriteconfig6 --file "$cf" --group "Plugin-org.kde.ActivityManager.Resources.Scoring" --key "keep-history-for" "1"

    cf="$HOME/.config/krunnerrc"
    kwriteconfig6 --file "$cf" --group "General" --key "FreeFloating" --type bool "true"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && cfg_kde
