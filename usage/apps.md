## Docker
```bash
echo "Installing docker..."
sudo pacman -S --noconfirm --needed docker >/dev/null

### 配置 Docker

daemon_file="/etc/docker/daemon.json"
sudo mkdir -p "$(dirname $daemon_file)"
sudo cp docker.config.json "$daemon_file"
sudo systemctl stop docker &>/dev/null
sudo usermod -aG docker "$USER" &>/dev/null
sudo systemctl daemon-reload
sudo systemctl start docker &>/dev/null
echo "✓ Docker configured"
echo "⚠ Please logout and login again for group changes to take effect"
```

## ardour.md

```bash
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

```

## blender.md

```bash
sudo pacman -S --needed --noconfirm blender
```

## Davinci_Resolve.md

```bash
### opencl driver
sudo pacman -S --needed --noconfirm rocm-opencl-runtime

yes | sudo $HOME/Downloads/DaVinci_Resolve_20.3.1_Linux/DaVinci_Resolve_20.3.1_Linux.run -i
###  /opt/resolve/bin/resolve: error while loading shared libraries: libcrypt.so.1: cannot open shared object file: No such file or directory
sudo pacman -S --needed --noconfirm libxcrypt-compat lib32-libxcrypt-compat
### /opt/resolve/bin/resolve: symbol lookup error: /usr/lib/libpango-1.0.so.0: undefined symbol: g_once_init_leave_pointer
LD_PRELOAD="/usr/lib/libgio-2.0.so /usr/lib/libgmodule-2.0.so /usr/lib/libglib-2.0.so" /opt/resolve/bin/resolve
##### Q
```

## VirtualBox.md

```bash
echo "Installing virtualbox..."
sudo pacman -S --noconfirm --needed virtualbox \
	linux$(uname -r | cut -d. -f1-2 | tr -d . | head -c3)-virtualbox-host-modules \
	virtualbox-ext-vnc >/dev/null

for mod in vboxdrv vboxnetadp vboxnetflt; do
	sudo modprobe "$mod" >/dev/null && echo "  ✓ Loaded $mod" || echo "  ✗ Failed to load $mod"
done
sudo usermod -aG vboxusers "$USER" && echo "  ✓ Added $USER to vboxusers group"
```
