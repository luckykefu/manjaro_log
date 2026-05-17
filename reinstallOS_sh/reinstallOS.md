## base cfg

```bash
kscreen-doctor -o
output=1
Modes=1
kscreen-doctor "output.${output}.mode.${Modes}"
```

```bash
lookandfeeltool -a org.manjaro.breath-dark.desktop --resetLayout
sudo pacman-mirrors -c China && sudo pacman -Sy --noconfirm
bash lib/pacman_cfg.sh
sudo systemctl enable fstrim.timer
tz=UTC && sudo timedatectl set-timezone "$tz" && sudo timedatectl set-ntp true
sudo chown -R "$USER:$USER" /data

sudo mkdir -p /.snapshots && sudo btrfs subvolume snapshot -r / /.snapshots/01_base_cfg
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
sudo btrfs subvolume snapshot -r / /.snapshots/01_sudo_nopassword
```

## ssh

```bash
bash lib/ssh.sh
```

## gpg

```bash
bash lib/gpg.sh
```

## git

```bash
git_cfg() {
    local name="${1:-kefu}" email="${2:-19157521820@163.com}"
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    git config --global credential.helper libsecret
    echo "git configured"
}
git_cfg
sudo btrfs subvolume snapshot -r / /.snapshots/03_ssh_gpg_git

```

## fcitx5

```bash
sudo pacman -S --needed --noconfirm fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki
kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop
## add methed pinyin
## reboot | relogin
sudo btrfs subvolume snapshot -r / /.snapshots/04_fcitx5
```

## zshrc

```bash
bash lib/zshrc.sh
sudo pacman -Syyu --noconfirm
sudo btrfs subvolume snapshot -r / /.snapshots/05_update_zshrc
sudo mkdir -p /home/.snapshots && sudo btrfs subvolume snapshot -r /home /home/.snapshots/01_update_zshrc
```

## packages

```bash
local base_pkg=(base-devel yay keepassxc rust zed jq yq shellcheck)
sudo pacman -S --noconfirm --needed "${base_pkg[@]}"
curl -fsSL https://opencode.ai/install | bash

local fonts_pkg=(inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation wqy-microhei wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts ttf-fira-code ttf-roboto)
sudo pacman -S --noconfirm --needed "${fonts_pkg[@]}"
sudo btrfs subvolume snapshot -r / /.snapshots/06_packages
sudo btrfs subvolume snapshot -r /home /home/.snapshots/02_packages
sudo btrfs subvolume snapshot -r /home /home/.snapshots/03_fcitx5_cfg
```

## shadowsocks-rust

reinstallOS_sh/shadowsocks-rust/README.md

```bash
sudo btrfs subvolume snapshot -r / /.snapshots/07_shadowsocks-rust
```

## yay

```bash
export all_proxy=socks5://127.0.0.1:1080
local yay_pkg=(cryptomator-bin)
yay -S --noconfirm --needed "${yay_pkg[@]}"
yay -Syyu --noconfirm
sudo btrfs subvolume snapshot -r / /.snapshots/08_cryptomator

```

## Tailscale

```bash
bash lib/tailscale.sh
```
## autostart

```bash
bash lib/autostart.sh
sudo btrfs subvolume snapshot -r /home /home/.snapshots/05_autostart
```
## cryptomator keepassxc firefox

```bash
sudo btrfs subvolume snapshot -r / /.snapshots/09_cryptomator_keepassxc_firefox_cfg
sudo btrfs subvolume snapshot -r /home /home/.snapshots/09_cryptomator_keepassxc_firefox_cfg
```




## kde theme
```bash
bash kde_cfg_sh/theme.sh
bash kde_cfg_sh/general.sh
sudo btrfs subvolume snapshot -r / /.snapshots/10_kde_cfg
sudo btrfs subvolume snapshot -r /home /home/.snapshots/10_kde_cfg
```
## telegram
```bash
sudo pacman -S --noconfirm --needed telegram-desktop
sudo btrfs subvolume snapshot -r / /.snapshots/11_telegram
sudo btrfs subvolume snapshot -r /home /home/.snapshots/11_telegram
```
## Cargo 镜像

```bash
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = 'rsproxy'
[source.rsproxy] registry = "https://rsproxy.cn/crates.io-index"
# 稀疏索引（Rust 1.68+ 支持，速度更快）
# [source.rsproxy-sparse]
# registry = "sparse+https://rsproxy.cn/index/"
# [registries.rsproxy]
# index = "https://rsproxy.cn/crates.io-index"
# 设置代理
# [net]
# git-fetch-with-cli = true
EOF
```
