#!/bin/bash

set -euo pipefail # if error , exit
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
# # ============================================================================
echo "Installing haveged..."
sudo pacman -S --noconfirm --needed haveged >/dev/null
sudo systemctl enable --now haveged >/dev/null

# # ============================================================================
echo "Installing virtualbox..."
sudo pacman -S --noconfirm --needed virtualbox \
	linux$(uname -r | cut -d. -f1-2 | tr -d . | head -c3)-virtualbox-host-modules \
	virtualbox-ext-vnc >/dev/null

for mod in vboxdrv vboxnetadp vboxnetflt; do
	sudo modprobe "$mod" >/dev/null && echo "  ✓ Loaded $mod" || echo "  ✗ Failed to load $mod"
done
sudo usermod -aG vboxusers "$USER" && echo "  ✓ Added $USER to vboxusers group"
# restart the systemd service for virtualbox

# # ============================================================================
echo "Installing docker..."
sudo pacman -S --noconfirm --needed docker >/dev/null
find_and_run docker_conf.sh

# # ============================================================================
echo "Installing aria2..."
sudo pacman -S --noconfirm --needed aria2 >/dev/null

# # ============================================================================
echo "Installing miniconda3..."
find_and_run pip_conf.sh
find_and_run miniconda3_conf.sh
# # ============================================================================
echo "Installing ardour..."
sudo pacman -S --noconfirm --needed ardour >/dev/null
#--> Configure audio limits --> 配置音频限制
sudo mkdir -p /etc/security/limits.d
sudo tee "/etc/security/limits.d/$USER-audio-unlimited.conf" >/dev/null <<EOF
@audio   -  rtprio     95
@audio   -  memlock    unlimited
EOF
sudo usermod -aG audio "$USER"

# # ============================================================================
echo "Installing zshplugins zsh-sudo..."
#--> Install zsh-sudo plugin --> 安装 zsh-sudo 插件
zsh_plugins_dir="/data/.zshplugins" && mkdir -p "$zsh_plugins_dir"
zsh_sudo_dir="$zsh_plugins_dir/zsh-sudo"

if [[ ! -d "$zsh_sudo_dir" ]]; then
	git clone https://github.com/none9632/zsh-sudo.git "$zsh_sudo_dir" >/dev/null
	echo "  ✓ Cloned zsh-sudo"
fi

#--> Add to .zshrc if not already present --> 如果尚未添加则添加到 .zshrc
if ! grep -q "zsh-sudo.zsh" ~/.zshrc 2>/dev/null; then
	echo "source $zsh_sudo_dir/zsh-sudo.zsh" >>~/.zshrc
	echo "  ✓ Added zsh-sudo to .zshrc"
fi

# # ============================================================================
echo "Installing mpv..."
sudo pacman -S --noconfirm --needed mpv ffmpeg >/dev/null

# # ============================================================================
echo "Installing telegram-desktop..."
sudo pacman -S --noconfirm --needed telegram-desktop >/dev/null

# # ============================================================================
echo "Installing obs-studio..."
sudo pacman -S --noconfirm --needed obs-studio >/dev/null

# # ============================================================================
echo "Installing qbittorrent..."
sudo pacman -S --noconfirm --needed qbittorrent >/dev/null

# # ============================================================================
echo "Installing ventoy..."
sudo pacman -S --noconfirm --needed ventoy >/dev/null

# # ============================================================================
echo "Installing wine..."
sudo pacman -S --noconfirm --needed wine wine-mono wine-gecko winetricks >/dev/null

# # ============================================================================
echo "Installing yabridge..."
sudo pacman -S --noconfirm --needed yabridgectl >/dev/null

# # ============================================================================
find_and_run path_append.sh "/data/.path/.appimage"
