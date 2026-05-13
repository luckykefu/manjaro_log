#!/usr/bin/env bash
# main.sh — Manjaro 系统重装自动化主入口
# DOC:
#   1. 环境检查（禁止 root 运行）
#   2. 加载 lib/*.zsh 工具函数
#   3. 应用主题 → 免密码 sudo → 镜像源 → 系统服务
#   4. 显示器刷新率 → SSH → GPG → Git → Shell rc → 代理
#   5. 系统包安装 → AUR 包安装 → 输入法 → 开机自启 → 全量更新
# 用法: bash main.sh

set -euo pipefail

# 1. 环境检查：禁止 root/sudo 运行
[[ $EUID -eq 0 ]] && { echo "error: do not run this script as root/sudo"; exit 1; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# 2. 加载 lib/ 下所有 .zsh 工具函数
if [[ -d "$LIB_DIR" ]]; then
    while IFS= read -r -d '' f; do
        source "$f"
    done < <(find "$LIB_DIR" -type f -name '*.zsh' -print0)
fi

main() {
    # 3. 基础系统配置
    info "应用主题..."
    lookandfeeltool -a org.manjaro.breath-dark.desktop
    sudo_nopassword
    sudo pacman-mirrors -c China
    sudo pacman -Sy --noconfirm
    sudo systemctl enable fstrim.timer
    sudo timedatectl set-timezone UTC && sudo timedatectl set-ntp true
    sudo chown -R "$USER:$USER" /data

    # 4. 用户环境配置
    display_rate_set 1 60
    ssh_config
    GPG_PASSPHRASE="lkf.Gpg.mima3" gpg_gen "kefu" "19157521820@163.com"
    git_config
    source_shrc
    ss_proxy_config "202.182.112.91"

    # 5. 系统包和 AUR 包安装
    sudo pacman -S --needed --noconfirm base-devel yay keepassxc rust zed opencode alacritty inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts  noto-fonts  noto-fonts-cjk  noto-fonts-emoji  ttf-dejavu  ttf-liberation  wqy-microhei  wqy-zenhei  adobe-source-han-sans-cn-fonts  adobe-source-han-serif-cn-fonts  ttf-fira-code  ttf-roboto  \
        bat fd ripgrep eza zoxide git-delta procs dust bottom \
        fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki
    all_proxy=socks5://127.0.0.1:1080 yay -S --needed --noconfirm clash-verge-rev-bin cryptomator-bin
    echo "clash-verge subscribe link: https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825"

    # 6. 输入法和开机自启
    setup_fcitx5
    auto_start

    # 7. 全量更新
    sudo pacman -Syyu --noconfirm
    all_proxy=socks5://127.0.0.1:1080 yay -Syyu --noconfirm
}

main "$@"
