sudo pacman -S --noconfirm --needed tailscale
sudo systemctl enable --now tailscaled
sudo systemctl enable --now sshd
sudo tailscale up
