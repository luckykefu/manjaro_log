#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -eq 0 ]] && { echo "error: do not run this script as root/sudo"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    [[ -f "$lib" ]] && source "$lib"
done

main() {
    info "应用主题..."
    lookandfeeltool -a org.manjaro.breath-dark.desktop
    sudo_nopassword
    sudo pacman-mirrors -c China
    sudo pacman -Sy --noconfirm
    sudo systemctl enable fstrim.timer
    sudo timedatectl set-timezone UTC && sudo timedatectl set-ntp true
    sudo chown -R "$USER:$USER" /data
    display_rate_set 1 60
    git_config
    ssh_config
    GPG_PASSPHRASE="lkf.Gpg.mima3" gpg_gen "kefu" "19157521820@163.com"
    source_shrc
    ss_proxy_config "202.182.112.91"
    sudo pacman -S --needed --noconfirm base-devel yay keepassxc rust zed opencode alacritty inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts  noto-fonts  noto-fonts-cjk  noto-fonts-emoji  ttf-dejavu  ttf-liberation  wqy-microhei  wqy-zenhei  adobe-source-han-sans-cn-fonts  adobe-source-han-serif-cn-fonts  ttf-fira-code  ttf-roboto  \
        bat fd ripgrep eza zoxide git-delta procs dust bottom \
        fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki
    all_proxy=socks5://127.0.0.1:1080 yay -S --needed --noconfirm clash-verge-rev-bin cryptomator-bin
    echo "clash-verge subscribe link: https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825"
    setup_fcitx5
    auto_start
    sudo pacman -Syyu --noconfirm
    all_proxy=socks5://127.0.0.1:1080 yay -Syyu --noconfirm
}

main "$@"
