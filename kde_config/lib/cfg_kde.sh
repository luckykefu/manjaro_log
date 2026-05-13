#!/usr/bin/env bash
set -euo pipefail

cfg_kde() {
    # ── 字体配置 ──
    local config_file="$HOME/.config/kdeglobals"
    kwriteconfig6 --file "$config_file" --group "General" --key "font"                 "Source Han Sans CN,10,-1,5,316,0,0,0,0,0,0,0,0,0,0,1,Normal"
    kwriteconfig6 --file "$config_file" --group "General" --key "menuFont"             "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$config_file" --group "General" --key "smallestReadableFont" "Source Han Sans CN,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$config_file" --group "General" --key "toolBarFont"          "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$config_file" --group "General" --key "fixed"                "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    kwriteconfig6 --file "$config_file" --group "WM"      --key "activeFont"           "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    # ── 鼠标/键盘配置 ──
    config_file="$HOME/.config/kcminputrc"
    kwriteconfig6 --file "$config_file" --group "Libinput" --group "4152" --group "5898" --group "SteelSeries SteelSeries Rival 100 Dell China" --key "PointerAcceleration" "1"
    kwriteconfig6 --file "$config_file" --group "Keyboard" --key "NumLock" "0"

    # ── KWin 窗口管理器配置 ──
    echo "✓ Configuring KWin..."
    config_file="$HOME/.config/kwinrc"
    kwriteconfig6 --file "$config_file" --group "Effect-overview"  --key "BorderActivate"  "1,7"
    kwriteconfig6 --file "$config_file" --group "ElectricBorders"  --key "BottomLeft"      "KRunner"
    kwriteconfig6 --file "$config_file" --group "ElectricBorders"  --key "TopLeft"         "ApplicationLauncher"
    kwriteconfig6 --file "$config_file" --group "TabBox"           --key "LayoutName"      "big_icons"
    kwriteconfig6 --file "$config_file" --group "General"          --key "FreeFloating"    --type bool true
    kwriteconfig6 --file "$config_file" --group "General"          --key "historyBehavior" "ImmediateCompletion"

    # ── KWin 特效开关 ──
    local -A animations=(
        [mouseclickEnabled]="true"
        [trackmouseEnabled]="true"
        [contrastEnabled]="true"
        [blurEnabled]="true"
        [fallapartEnabled]="false"
        [mousemarkEnabled]="true"
        [translucencyEnabled]="true"
        [wobblywindowsEnabled]="true"
        [magiclampEnabled]="true"
        [squashEnabled]="false"
        [diminactiveEnabled]="true"
        [glideEnabled]="true"
        [scaleEnabled]="false"
    )
    for key in "${!animations[@]}"; do
        kwriteconfig6 --file "$config_file" --group "Plugins" --key "$key" --type bool "${animations[$key]}"
    done

    # ── 屏幕锁定配置 ──
    echo "✓ Configuring screen locker..."
    config_file="$HOME/.config/kscreenlockerrc"
    kwriteconfig6 --file "$config_file" --group "Daemon" --key "Timeout"          "0"
    kwriteconfig6 --file "$config_file" --group "Daemon" --key "LockGrace"        "900"
    kwriteconfig6 --file "$config_file" --group "Daemon" --key "RequirePassword"  "false"
    kwriteconfig6 --file "$config_file" --group "Daemon" --key "Autolock"         "false"

    # ── 活动管理器配置 ──
    echo "✓ Configuring activity manager..."
    config_file="$HOME/.config/kactivitymanagerd-pluginsrc"
    kwriteconfig6 --file "$config_file" --group "Plugin-org.kde.ActivityManager.Resources.Scoring" --key "keep-history-for" "1"

    # ── KRunner 配置 ──
    config_file="$HOME/.config/krunnerrc"
    kwriteconfig6 --file "$config_file" --group "General" --key "FreeFloating" --type bool "true"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && cfg_kde