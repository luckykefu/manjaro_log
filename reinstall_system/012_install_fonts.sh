#!/usr/bin/env bash
set -euo pipefail

# 需要安装的字体列表
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
