%%bash
## 制作 USB LIVE
## 下载 Manjaro KDE ISO
## 备份数据
## 重启安装 Manjaro KDE
## 配置系统
bash add_zshrc_config.sh
bash link_to_home.sh
gpg --gen-keys
bash set_mirror.sh
bash cfg_git.sh
bash gen_ssh_key.sh
sudo pacman -S --needed --noconfirm \
	fcitx5 \
	fcitx5-gtk \
	fcitx5-qt \
	fcitx5-configtool \
	fcitx5-chinese-addons \
	fcitx5-pinyin-zhwiki 
kwriteconfig6 --file kwinrc --group Wayland --key 'InputMethod' /usr/share/applications/org.fcitx.Fcitx5.desktop

sudo pacman -Sy --needed --noconfirm base-devel yay uv
sudo pacman -S --needed --noconfirm manjaro-keyring archlinux-keyring archlinuxcn-keyring 
sudo pacman-key --init 
sudo pacman-key --populate archlinux manjaro archlinuxcn 
sudo pacman -Syy --noconfirm 
sudo pacman -Syyu --noconfirm 
yay -Syyu --noconfirm 
yay -S --needed --noconfirm  cryptomator-bin clash-verge-rev-bin keepassxc
yay -S --needed --noconfirm visual-studio-code-bin
bash add_autostart.sh
# vscode
# 3124568493@qq.com
# cryptomator
# /data/.cryptomator

# keepassxc
# /data/.manjaro/backup_data

# clash-verge
# sub link : https://zhuzhuzhu.whtjdasha.com/api/v1/client/subscribe?token=eebe36f8c2eb695b9841a61eb4b03825
# setting : auto start; slient start ; allow lan;

## 配置 KDE
systemsettings kcm_kscreen
bash install_themes.sh

kcmshell6 kcm_lookandfeel
systemctl is-active --quiet bluetooth && sudo systemctl disable --now bluetooth || true

bash config_kde_clock.sh
bash config_kde_wallpaper.sh
bash config_kde_launchers.sh
bash install_fonts.sh
bash cfg_kde.sh

## 安装软件
sudo pacman -S --noconfirm --needed haveged aria2 mpv ffmpeg telegram-desktop obs-studio qbittorrent ventoy nodejs npm
sudo systemctl enable --now haveged
sudo pacman -Syyu --noconfirm
yay -Syyu --noconfirm

sudo pacman -S --needed --noconfirm \
    mesa \
    lib32-mesa \
    vulkan-radeon \
    lib32-vulkan-radeon \
    libva-mesa-driver \
    lib32-libva-mesa-driver \
    xf86-video-amdgpu \
    rocm-opencl-runtime \
    rocm-hip-runtime