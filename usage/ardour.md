```bash
%%bash
echo "Installing ardour..."
sudo pacman -S --noconfirm --needed ardour >/dev/null

sudo mkdir -p /etc/security/limits.d
sudo tee "/etc/security/limits.d/$USER-audio-unlimited.conf" >/dev/null <<EOF
@audio   -  rtprio     95
@audio   -  memlock    unlimited
EOF
sudo usermod -aG audio "$USER"


# LANGUAGE=zh_CN.UTF-8 ardour8
```
