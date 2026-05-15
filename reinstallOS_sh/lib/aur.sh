aur() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && pkgs=("cryptomator-bin")
    echo "installing AUR packages: ${pkgs[*]}"
    yay -S --noconfirm --needed "${pkgs[@]}"
    echo "AUR packages installed"
}
