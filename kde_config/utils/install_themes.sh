#!/bin/bash
# ============================================================================
# Script: install_themes.sh
# Description: Install WhiteSur KDE themes (icons, cursors, and desktop theme)
# ============================================================================

#--> Check if theme is installed --> 检查主题是否已安装
is_theme_installed() {
	local theme_name="$1"
	case "$theme_name" in
	WhiteSur-icon-theme)
		[[ -d "$HOME/.local/share/icons/WhiteSur" ]] || [[ -d "$HOME/.icons/WhiteSur" ]]
		;;
	WhiteSur-kde)
		[[ -d "$HOME/.local/share/plasma/desktoptheme/WhiteSur" ]]
		;;
	WhiteSur-cursors)
		[[ -d "$HOME/.local/share/icons/WhiteSur-cursors" ]] || [[ -d "$HOME/.icons/WhiteSur-cursors" ]]
		;;
	*)
		return 1
		;;
	esac
}

#--> Install theme from git repository --> 从 git 仓库安装主题
install_theme() {
	local git_url="$1"
	local themes_dir="${2:-$HOME/Downloads/.themes}"
	local theme_name
	theme_name=$(basename "$git_url" .git)

	# 检查是否已安装
	if is_theme_installed "$theme_name"; then
		echo "  ✓ $theme_name already installed, skipping"
		return 0
	fi

	mkdir -p "$themes_dir"
	cd "$themes_dir" || return 1

	local theme_path="$themes_dir/$theme_name"

	if [[ ! -d "$theme_path" ]]; then
		git clone "$git_url" &>/dev/null && echo "  ✓ Cloned $theme_name"
	fi

	cd "$theme_path" || return 1

	# Build cursors BEFORE install
	if [[ "$theme_name" == "WhiteSur-cursors" && -f "build.sh" ]]; then
		bash build.sh &>/dev/null && echo "  ✓ Built cursors"
	fi

	if [[ -f "install.sh" ]]; then
		bash install.sh && echo "  ✓ Installed $theme_name"
	fi

	# Delete after installation
	rm -rf "$theme_path" && echo "  ✓ Cleaned $theme_name"
}

#--> Install multiple themes --> 安装多个主题
install_themes() {
	local urls="https://github.com/vinceliuice/WhiteSur-icon-theme.git
https://github.com/vinceliuice/WhiteSur-kde.git
https://github.com/vinceliuice/WhiteSur-cursors.git"

	echo "🎨 Installing themes..."
	while IFS= read -r url; do
		url=$(echo "$url" | xargs)
		[[ -z "$url" ]] && continue
		echo "Installing theme from: $url"
		install_theme "$url"
	done <<<"$urls"
	echo "✓ All themes processed"
}
