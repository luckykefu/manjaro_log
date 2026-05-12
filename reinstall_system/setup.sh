#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."  # 确保在脚本目录下执行
info()  { echo -e "\e[1;34m[*]\e[0m $*"; }
ok()    { echo -e "\e[1;32m[✓]\e[0m $*"; }
skip()  { echo -e "\e[1;33m[-]\e[0m $*"; }

# ── 主题 ──
info "应用主题..."
lookandfeeltool -a org.manjaro.breath-dark.desktop
scripts/sudo_nopassword.sh
sudo pacman-mirrors -c China
sudo pacman -Sy --noconfirm
sudo systemctl enable fstrim.timer
# 设置所有显示器为最低刷新率
output=$(kscreen-doctor -o | grep -m1 "enabled" | awk '{print $3}')
lowest=$(kscreen-doctor -o | sed -n "/$output/,/^Output:/p" | \
    grep -oP '\d+:\d+x\d+@\d+' | sort -t@ -k2 -n | head -1 | cut -d: -f1)
kscreen-doctor "output.${output}.mode.${lowest}"
sudo timedatectl set-timezone UTC
sudo timedatectl set-ntp true
sudo chown -R $USER:$USER /data

# ── Git / SSH ──
info "配置 Git..."
scripts/git_config.sh
info "配置 SSH..."
scripts/ssh_config.sh
info "cfg gpg_gen"
GPG_PASSPHRASE="lkf.Gpg.mima3" scripts/gpg_gen.sh "kefu" "19157521820@163.com" --yes
# ── SS 代理 ──
info "启动 SS 代理..."
scripts/ss_proxy_config.sh 202.182.112.91

# ── 系统包 ──
info "安装系统依赖..."
sudo pacman -S --needed --noconfirm base-devel yay keepassxc rust zed opencode
# ── AUR 包 ──
info "安装 AUR 包 (通过代理)..."
yay -S --needed --noconfirm clash-verge-rev-bin cryptomator-bin
echo "clash-verge subscribe link: https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825"
scripts/setup_fcitx5.sh
scripts/012_install_fonts.sh
scripts/auto_start.sh
scripts/update.sh
