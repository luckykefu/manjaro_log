#!/usr/bin/env bash
set -euo pipefail

echo "Installing ardour..."
sudo pacman -S --noconfirm --needed ardour >/dev/null

sudo mkdir -p /etc/security/limits.d
sudo tee "/etc/security/limits.d/$USER-audio-unlimited.conf" >/dev/null <<LIMITS
@audio   -  rtprio     95
@audio   -  memlock    unlimited
LIMITS

sudo usermod -aG audio "$USER"

echo "Audio setup done. Re-login or run: newgrp audio"
