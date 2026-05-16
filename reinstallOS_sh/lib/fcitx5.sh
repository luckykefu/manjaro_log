fcitx5() {
    echo "installing fcitx5 packages"
    sudo pacman -S --needed --noconfirm fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki
    kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local src="$SCRIPT_DIR/fcitx5"
    [[ -d "$src" ]] && { local dst="$HOME/.config/fcitx5";  rm -rf "$dst";ln -sf "$src" "$dst" && echo "fcitx5 config linked"; }
    echo "fcitx5 setup complete"
}
fcitx5
