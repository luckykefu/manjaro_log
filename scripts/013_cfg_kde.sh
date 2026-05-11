#!/usr/bin/env bash
set -euo pipefail

# ── 字体配置 ──────────────────────────────────────────────
config_file="$HOME/.config/kdeglobals"
kwriteconfig6 --file "$config_file" --group "General" --key "font"                 "Source Han Sans CN,10,-1,5,316,0,0,0,0,0,0,0,0,0,0,1,Normal"  # 默认字体
kwriteconfig6 --file "$config_file" --group "General" --key "menuFont"             "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "General" --key "smallestReadableFont" "Source Han Sans CN,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "General" --key "toolBarFont"          "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "General" --key "fixed"                "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "WM"      --key "activeFont"           "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"  # 标题栏字体

# ── 鼠标/键盘配置 ─────────────────────────────────────────
unset config_file
config_file="$HOME/.config/kcminputrc"
kwriteconfig6 --file "$config_file" --group "Libinput" --group "4152" --group "5898" --group "SteelSeries SteelSeries Rival 100 Dell China" --key "PointerAcceleration" "1"  # 鼠标加速
kwriteconfig6 --file "$config_file" --group "Keyboard" --key "NumLock" "0"  # 开机关闭 NumLock

# ── KWin 窗口管理器配置 ───────────────────────────────────
echo "✓ Configuring KWin..."
unset config_file
config_file="$HOME/.config/kwinrc"
kwriteconfig6 --file "$config_file" --group "Effect-overview"  --key "BorderActivate"  "1,7"                  # 触发概览的热角
kwriteconfig6 --file "$config_file" --group "ElectricBorders"  --key "BottomLeft"      "KRunner"              # 左下角触发 KRunner
kwriteconfig6 --file "$config_file" --group "ElectricBorders"  --key "TopLeft"         "ApplicationLauncher"  # 左上角触发启动器
kwriteconfig6 --file "$config_file" --group "TabBox"           --key "LayoutName"      "big_icons"            # Alt+Tab 大图标样式
kwriteconfig6 --file "$config_file" --group "General"          --key "FreeFloating"    --type bool true        # KRunner 自由浮动
kwriteconfig6 --file "$config_file" --group "General"          --key "historyBehavior" "ImmediateCompletion"  # 历史补全

# ── KWin 特效开关 ─────────────────────────────────────────
declare -A animations=(
    ["mouseclickEnabled"]="true"    # 鼠标点击特效
    ["trackmouseEnabled"]="true"    # 鼠标轨迹
    ["contrastEnabled"]="true"      # 对比度
    ["blurEnabled"]="true"          # 模糊
    ["fallapartEnabled"]="false"    # 窗口碎裂（关闭）
    ["mousemarkEnabled"]="true"     # 鼠标标记
    ["translucencyEnabled"]="true"  # 透明度
    ["wobblywindowsEnabled"]="true" # 果冻窗口
    ["magiclampEnabled"]="true"     # 魔术灯最小化
    ["squashEnabled"]="false"       # 压缩最小化（关闭，与 magiclamp 互斥）
    ["diminactiveEnabled"]="true"   # 非活动窗口变暗
    ["glideEnabled"]="true"         # 滑动
    ["scaleEnabled"]="false"        # 缩放（关闭）
)

for key in "${!animations[@]}"; do
    kwriteconfig6 --file "$config_file" --group "Plugins" --key "$key" --type bool "${animations[$key]}"
done

# ── 屏幕锁定配置 ──────────────────────────────────────────
echo "✓ Configuring screen locker..."
unset config_file
config_file="$HOME/.config/kscreenlockerrc"
kwriteconfig6 --file "$config_file" --group "Daemon" --key "Timeout"          "0"      # 不自动锁屏
kwriteconfig6 --file "$config_file" --group "Daemon" --key "LockGrace"        "900"    # 锁屏宽限期
kwriteconfig6 --file "$config_file" --group "Daemon" --key "RequirePassword"  "false"  # 解锁不需要密码
kwriteconfig6 --file "$config_file" --group "Daemon" --key "Autolock"         "false"  # 关闭自动锁屏

# ── 活动管理器配置 ────────────────────────────────────────
echo "✓ Configuring activity manager..."
config_file="$HOME/.config/kactivitymanagerd-pluginsrc"
kwriteconfig6 --file "$config_file" --group "Plugin-org.kde.ActivityManager.Resources.Scoring" --key "keep-history-for" "1"  # 历史记录保留1天
unset config_file

# ── KRunner 配置 ──────────────────────────────────────────
config_file="$HOME/.config/krunnerrc"
kwriteconfig6 --file "$config_file" --group "General" --key "FreeFloating" --type bool "true"  # KRunner 自由浮动
