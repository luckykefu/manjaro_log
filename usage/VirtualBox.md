```bash
%%bash
echo "Installing virtualbox..."
sudo pacman -S --noconfirm --needed virtualbox \
	linux$(uname -r | cut -d. -f1-2 | tr -d . | head -c3)-virtualbox-host-modules \
	virtualbox-ext-vnc >/dev/null

for mod in vboxdrv vboxnetadp vboxnetflt; do
	sudo modprobe "$mod" >/dev/null && echo "  ✓ Loaded $mod" || echo "  ✗ Failed to load $mod"
done
sudo usermod -aG vboxusers "$USER" && echo "  ✓ Added $USER to vboxusers group"
```
