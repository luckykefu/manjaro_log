#!/usr/bin/env bash
set -euo pipefail
## base cfg
lookandfeeltool -a org.manjaro.breath-dark.desktop --resetLayout
sudo pacman-mirrors -c China
sudo pacman -Sy --noconfirm
sudo systemctl enable fstrim.timer
tz=UTC && sudo timedatectl set-timezone "$tz" && sudo timedatectl set-ntp true

## update
sudo pacman -Syyu --noconfirm

## linux70
sudo pacman -S --needed --noconfirm linux70 linux70-headers
sudo grub-set-default "0>"

## fcitx5
sudo pacman -S --needed --noconfirm fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki
kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash ${SCRIPT_DIR}/theme.sh
bash ${SCRIPT_DIR}/general.sh

reboot
