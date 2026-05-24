## org

```bash
sudo mkdir -p /.snapshots /home/.snapshots
ls -a / /home
sudo btrfs subvolume snapshot -r / /.snapshots/000_org
sudo btrfs subvolume snapshot -r /home /home/.snapshots/000_org
ls -a /.snapshots /home/.snapshots
```

## display

```bash
set -euo pipefail
kscreen-doctor -o
output=1
Modes=1
kscreen-doctor "output.${output}.mode.${Modes}"
sudo btrfs subvolume snapshot -r / /.snapshots/001_display60hz
sudo btrfs subvolume snapshot -r /home /home/.snapshots/001_display60hz
ls -a /.snapshots /home/.snapshots
```

## sudo nopassword

```bash
sudo_nopassword() {
    local sudoers_file="/etc/sudoers.d/${USER}_nopassword"
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee $sudoers_file
    sudo chmod 0440 "$sudoers_file"
    sudo visudo -c
}
sudo_nopassword
sudo btrfs subvolume snapshot -r / /.snapshots/002_sudo_nopassword
```

## base cfg

```bash
lookandfeeltool -a org.manjaro.breath-dark.desktop --resetLayout
sudo pacman-mirrors -c China && sudo pacman -Sy --noconfirm
bash lib/pacman_cfg.sh
sudo systemctl enable fstrim.timer
tz=UTC && sudo timedatectl set-timezone "$tz" && sudo timedatectl set-ntp true
sudo chown -R "$USER:$USER" /data

sudo mkdir -p /.snapshots && sudo btrfs subvolume snapshot -r / /.snapshots/003_base_cfg
```

## zed opencode

```bash

curl -fsSL https://opencode.ai/install | bash
curl -f https://zed.dev/install.sh | sh
sudo btrfs subvolume snapshot -r /home /home/.snapshots/002_zed_opencode

```

## gpg

```bash
bash lib/gpg.sh
create_snapshot(){
    local snapshot_name=$1
    sudo btrfs subvolume snapshot -r / /.snapshots/"$snapshot_name"
    sudo btrfs subvolume snapshot -r /home /home/.snapshots/"$snapshot_name"
    ls -a /.snapshots /home/.snapshots
}
create_snapshot 004_gpg
```

## linux70

```bash
sudo pacman -S --needed --noconfirm linux70 linux70-headers
sudo grub-set-default "Advanced options for Manjaro>linux70-7.0.9-1-MANJARO"
create_snapshot 005_linux70

```

## update

```bash
sudo pacman -Syyu --noconfirm
bash lib/create_snapshot.sh 006_update
```

## ssh

```bash
bash lib/ssh.sh
bash lib/create_snapshot.sh 007_ssh
```

## git

```bash
bash lib/git.sh
bash lib/create_snapshot.sh 008_git
```

## fcitx5

```bash
bash lib/fcitx5.sh
## reboot | relogin
## add methed pinyin
# ctrl + .
bash lib/create_snapshot.sh 009_fcitx5
```

## zshrc

```bash
bash lib/zshrc.sh
bash lib/create_snapshot.sh 010_zshrc
```

## kde theme

```bash
bash kde_cfg/theme.sh
bash kde_cfg/general.sh
bash lib/create_snapshot.sh 011_kde

```

## packages

```bash
base_pkg=(base-devel yay keepassxc jq yq shellcheck)
sudo pacman -S --noconfirm --needed "${base_pkg[@]}"
bash lib/create_snapshot.sh 012_base_pkg

fonts_pkg=(inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation wqy-microhei wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts ttf-fira-code ttf-roboto)
sudo pacman -S --noconfirm --needed "${fonts_pkg[@]}"
bash lib/create_snapshot.sh 013_fonts_pkg

```

## yay

```bash
export all_proxy=socks5://127.0.0.1:1080
yay_pkg=(cryptomator-bin)
yay -S --noconfirm --needed "${yay_pkg[@]}"
yay -Syyu --noconfirm
bash lib/create_snapshot.sh 014_yay_pkg
```

## cryptomator keepassxc firefox

```bash
## autostart
app=cryptomator
found=$(find /usr/share/applications -iname "*${app}*" -name "*.desktop" -print -quit 2>/dev/null)
cp -f "$found" "$HOME/.config/autostart/$(basename "$found")" && ls $HOME/.config/autostart
bash lib/create_snapshot.sh 015_cryptomator_keepassxc_firefox_cfg
```

## shadowsocks-rust

reinstallOS_sh/shadowsocks-rust/README.md

```bash
bash lib/create_snapshot.sh 016_shadowsocks-rust
```

## Tailscale

```bash
bash lib/tailscale.sh

bash lib/create_snapshot.sh 017_tailscale
```

## telegram

```bash
sudo pacman -S --noconfirm --needed telegram-desktop
bash lib/create_snapshot.sh 018_telegram
```
## nautilustrader

```bash
curl https://sh.rustup.rs -sSf | sh
sudo pacman -S --noconfirm --needed clang lld
sudo pacman -S --noconfirm --needed capnproto
sudo pacman -S  --noconfirm --needed redis
sudo systemctl enable --now redis
bash lib/create_snapshot.sh 019_nautilustrader
```
