update() {
    echo "updating system packages"
    sudo pacman -Syyu --noconfirm
    echo "updating AUR packages"
    yay -Syyu --noconfirm
    echo "full update complete"
}
