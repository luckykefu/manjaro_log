## org

```bash
sudo mkdir -p /.snapshots 
ls -a /.*
sudo btrfs subvolume snapshot -r / /.snapshots/000_org
```
## sudo nopassword
```bash
sudoers_file="/etc/sudoers.d/${USER}_nopassword"
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee $sudoers_file
sudo chmod 0440 "$sudoers_file"
sudo visudo -c
reinstallOS/lib/create_snapshot.sh 000_sudo_nopassword
```
## base cfg
```bash
bash reinstallOS/lib/base_cfg.sh
reinstallOS/lib/create_snapshot.sh 001_base_cfg
```

## display

```bash
kscreen-doctor -o
output=1
Modes=1
kscreen-doctor "output.${output}.mode.${Modes}"
```

## zed opencode

```bash
export all_proxy=socks5h://127.0.0.1:7890
curl -fsSL https://opencode.ai/install | bash
curl -f https://zed.dev/install.sh | sh
reinstallOS/lib/create_snapshot.sh 006_zed_opencode
```

## yay

```bash
export all_proxy=socks5h://127.0.0.1:7890
yay_pkg=(cryptomator-bin)
yay -S --noconfirm --needed "${yay_pkg[@]}"
yay -Syyu --noconfirm
## cryptomator keepassxc firefox
## autostart
app=cryptomator
found=$(find /usr/share/applications -iname "*${app}*" -name "*.desktop" -print -quit 2>/dev/null)
cp -f "$found" "$HOME/.config/autostart/$(basename "$found")" && ls $HOME/.config/autostart
reinstallOS/lib/create_snapshot.sh 010_cryptomator
```
