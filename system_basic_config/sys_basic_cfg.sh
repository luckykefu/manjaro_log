#!/bin/bash

# # ============================================================================
# # System Basic Configuration
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

# # ============================================================================
set -euo pipefail # # if error , exit

# # ============================================================================
echo "home link make..."
d="/data/.home"
# 列出f 下 所有文件夹 不包含本身,
while IFS= read -r i; do
	rm -fr "$HOME/$(basename "$i")"
	ln -sf "$i" "$HOME/$(basename "$i")"
done < <(find "$d" -mindepth 1 -maxdepth 1 -type d)

sudo fuser -k /var/lib/pacman/db.lck 2>/dev/null || true
sudo rm -f /var/lib/pacman/db.lck

# # >>> 设置中国镜像源 <<<
echo "change pacman mirror..."
sudo tee /etc/pacman.d/mirrorlist >/dev/null <<'EOF'
# # China mirrors
Server = https://mirrors.ustc.edu.cn/manjaro/stable/$repo/$arch
EOF

echo "installing yay..."
sudo pacman -Sy --needed --noconfirm base-devel yay >/dev/null
#
find_and_run yay_conf.sh

find_and_run archlinuxcn_conf.sh
find_and_run pacman_conf.sh
# # ============================================================================
echo "update system..."
sudo pacman -Syyu --noconfirm >/dev/null
yay -Syyu --noconfirm >/dev/null

find_and_run gpg_conf.sh
yay -S --needed --noconfirm visual-studio-code-bin >/dev/null

echo "installing jupyter..."
sudo pacman -S --needed --noconfirm python-pip python-ipykernel jupyter-notebook >/dev/null

f=$HOME/.jupyter/jupyter_notebook_config.py
[[ -f "$f" ]] || jupyter notebook --generate-config

l="c.ContentsManager.line_numbers = True"
grep "$l" $f >/dev/null || echo "$l" >>$f
unset f l

echo "installing google-chrome..."
yay -S --needed --noconfirm google-chrome >/dev/null

echo "installing keepassxc..."
sudo pacman -S --needed --noconfirm keepassxc >/dev/null

echo "installing cryptomator..."
yay -S --needed --noconfirm cryptomator-bin >/dev/null

echo "installing pacman-key..."
sudo pacman -S --needed --noconfirm manjaro-keyring archlinux-keyring archlinuxcn-keyring >/dev/null
sudo pacman-key --init >/dev/null
sudo pacman-key --populate archlinux manjaro archlinuxcn >/dev/null
sudo pacman -Syy --noconfirm >/dev/null

echo "installing clash-verge..."
sudo pacman -S --needed --noconfirm clash-verge-rev >/dev/null

echo "installing fcitx5..."
sudo pacman -S --needed --noconfirm \
	fcitx5 \
	fcitx5-gtk \
	fcitx5-qt \
	fcitx5-configtool \
	fcitx5-chinese-addons \
	fcitx5-pinyin-zhwiki >/dev/null
kwriteconfig6 --file kwinrc --group Wayland --key 'InputMethod' /usr/share/applications/org.fcitx.Fcitx5.desktop

find_and_run git_conf.sh
find_and_run ssh_conf.sh
find_and_run autostart_conf.sh "cryptomator"

cryptomator >/dev/null &
keepassxc >/dev/null &
code . >/dev/null &
clash-verge >/dev/null &
i=$(ip addr show | grep -E 'inet.*global' | awk '{print $2}' | cut -d'/' -f1 | head -n1) && echo "Using IP: $i "
google-chrome-stable --proxy-server="socks5://${i}:7897" >/dev/null &
unset i
echo "Done!!!"
