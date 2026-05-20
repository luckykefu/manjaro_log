sudo pacman -S --noconfirm --needed tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
