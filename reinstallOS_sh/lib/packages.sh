packages() {
    local base_pkg=(base-devel yay keepassxc rust zed opencode wezterm)
    local fonts_pkg=(inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation wqy-microhei wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts ttf-fira-code ttf-roboto)
    local shell_tools=(ripgrep dust)

    echo "installing base packages (${#base_pkg[@]})"
    sudo pacman -S --noconfirm --needed "${base_pkg[@]}"

    echo "installing fonts (${#fonts_pkg[@]})"
    sudo pacman -S --noconfirm --needed "${fonts_pkg[@]}"

    echo "installing shell tools (${#shell_tools[@]})"
    sudo pacman -S --noconfirm --needed "${shell_tools[@]}"

    echo "all packages installed"
}
