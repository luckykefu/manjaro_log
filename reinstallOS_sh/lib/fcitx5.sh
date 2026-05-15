fcitx5() {
    echo "installing fcitx5 packages"
    sudo pacman -S --needed --noconfirm fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki
    command -v kwriteconfig6 &>/dev/null && { echo "configuring Wayland input method"; kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop; }
    local src_dir="/data/.manjaro/reinstallOS/fcitx5"
    [[ -d "$src_dir" ]] && { local dst="$HOME/.config/fcitx5" bak="${dst}.bak"; [[ -d "$bak" ]] && rm -rf "$bak"; [[ -e "$dst" ]] && mv "$dst" "$bak"; ln -sf "$src_dir" "$dst" && echo "fcitx5 config linked"; }
    echo "fcitx5 setup complete"
}
