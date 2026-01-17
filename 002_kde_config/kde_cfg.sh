#!/bin/bash
# # ============================================================================
# # kde Configuration
# # ============================================================================
find_and_run() {
	local file=$1 func=${1%.sh}
	shift 1

	local script
	script=$(find . -type f -name "$file" -print -quit)

	if [[ -z "$script" ]]; then
		echo "Error: $file not found" >&2
		return 1
	fi

	echo "Running $script -> $func"
	source "$script"

	if ! declare -F "$func" >/dev/null; then
		echo "Error: function '$func' not found in $script" >&2
		return 2
	fi

	"$func" "$@"
}

set -euo pipefail

# # ============================================================================
systemsettings kcm_kscreen

# # ============================================================================
find_and_run install_dolphin_vscode.sh
# # ============================================================================
find_and_run install_themes.sh
kcmshell6 kcm_lookandfeel

# # ============================================================================
systemctl is-active --quiet bluetooth && sudo systemctl disable --now bluetooth || true

# # ============================================================================
find_and_run wallpaper_conf.sh
# # ============================================================================
fonts="inter-font
adobe-source-han-sans-otc-fonts
adobe-source-han-serif-otc-fonts 
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
ttf-dejavu
ttf-liberation
wqy-microhei
wqy-zenhei
adobe-source-han-sans-cn-fonts
adobe-source-han-serif-cn-fonts
ttf-fira-code
ttf-roboto"
echo "✓ Installing fonts..."
for font in $fonts; do
	sudo pacman -Sy --needed --noconfirm "$font" &>/dev/null && echo "  ✓ $font installed"
done

# # ============================================================================
config_file="$HOME/.config/kdeglobals"
kwriteconfig6 --file "$config_file" --group "General" --key "font" "Source Han Sans CN,10,-1,5,316,0,0,0,0,0,0,0,0,0,0,1,Normal"
kwriteconfig6 --file "$config_file" --group "General" --key "menuFont" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "General" --key "smallestReadableFont" "Source Han Sans CN,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "General" --key "toolBarFont" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "General" --key "fixed" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$config_file" --group "WM" --key "activeFont" "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
unset config_file

# # ============================================================================
#--> Configure mouse --> 配置鼠标
config_file="$HOME/.config/kcminputrc"
kwriteconfig6 --file "$config_file" --group "Libinput" --group "4152" --group "5898" --group "SteelSeries SteelSeries Rival 100 Dell China" --key "PointerAcceleration" "1"
kwriteconfig6 --file "$config_file" --group "Keyboard" --key "NumLock" "0"
unset config_file

# # ============================================================================
#--> Configure KWin --> 配置 KWin
echo "✓ Configuring KWin..."
config_file="$HOME/.config/kwinrc"
kwriteconfig6 --file "$config_file" --group "Effect-overview" --key "BorderActivate" "1,7"
kwriteconfig6 --file "$config_file" --group "ElectricBorders" --key "BottomLeft" "KRunner"
kwriteconfig6 --file "$config_file" --group "ElectricBorders" --key "TopLeft" "ApplicationLauncher"
kwriteconfig6 --file "$config_file" --group "TabBox" --key "LayoutName" "big_icons"

kwriteconfig6 --file "$config_file" --group "General" --key "FreeFloating" --type bool true
kwriteconfig6 --file "$config_file" --group "General" --key "historyBehavior" "ImmediateCompletion"

# # ============================================================================
# config_file="$HOME/.config/kwinrc"
#--> Configure animations --> 配置动画效果
declare -A animations=(
	["mouseclickEnabled"]="true"
	["trackmouseEnabled"]="true"
	["contrastEnabled"]="true"
	["blurEnabled"]="true"
	["fallapartEnabled"]="false"
	["mousemarkEnabled"]="true"
	["translucencyEnabled"]="true"
	["wobblywindowsEnabled"]="true"
	["magiclampEnabled"]="true"
	["squashEnabled"]="false"
	["diminactiveEnabled"]="true"
	["glideEnabled"]="true"
	["scaleEnabled"]="false"
)

for key in "${!animations[@]}"; do
	kwriteconfig6 --file "$config_file" --group "Plugins" --key "$key" --type bool "${animations[$key]}"
done
unset config_file

# # ============================================================================
#--> Configure screen locker --> 配置屏幕锁定
echo "✓ Configuring screen locker..."
config_file="$HOME/.config/kscreenlockerrc"
kwriteconfig6 --file "$config_file" --group "Daemon" --key "Timeout" "0"
kwriteconfig6 --file "$config_file" --group "Daemon" --key "LockGrace" "900"
kwriteconfig6 --file "$config_file" --group "Daemon" --key "RequirePassword" "false"
kwriteconfig6 --file "$config_file" --group "Daemon" --key "Autolock" "false"
unset config_file

# # ============================================================================
#--> Configure activity manager --> 配置活动管理器
echo "✓ Configuring activity manager..."
config_file="$HOME/.config/kactivitymanagerd-pluginsrc"
kwriteconfig6 --file "$config_file" --group "Plugin-org.kde.ActivityManager.Resources.Scoring" --key "keep-history-for" "1"
unset config_file

# # ============================================================================
config_file="$HOME/.config/krunnerrc"
kwriteconfig6 --file "$config_file" --group "General" --key "FreeFloating" --type bool "true"
unset config_file

# # ============================================================================
kquitapp6 plasmashell && kstart plasmashell &
qdbus6 org.kde.KWin /KWin reconfigure

echo "✓ KDE configuration completed."
