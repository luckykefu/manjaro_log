#!/usr/bin/env bash
set -euo pipefail

setup_fcitx5() {
    # 安装 Fcitx5 输入法及相关组件
    sudo pacman -S --needed --noconfirm \
        fcitx5 \
        fcitx5-gtk \
        fcitx5-qt \
        fcitx5-configtool \
        fcitx5-chinese-addons \
        fcitx5-pinyin-zhwiki

    # 配置 KDE Wayland 输入法
    kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop

    echo "✓ Fcitx5 输入法安装完成"
    echo "✓ KDE Wayland 输入法已配置"
    echo "⚠ 请注销并重新登录以生效"
    cd "$(dirname "$0")"
    rm -rf $HOME/.config/fcitx5
    cp -r fcitx5 $HOME/.config/fcitx5
}

setup_fcitx5
