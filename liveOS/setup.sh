#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

info()  { echo -e "\e[1;34m[*]\e[0m $*"; }
ok()    { echo -e "\e[1;32m[✓]\e[0m $*"; }
skip()  { echo -e "\e[1;33m[-]\e[0m $*"; }

# ── 主题 ──
info "应用主题..."
lookandfeeltool -a org.manjaro.breath-dark.desktop

# ── Git / SSH ──
info "配置 Git..."
bash ../scripts/gitConfig.sh

info "配置 SSH..."
bash ../scripts/sshConfig.sh

info "cfg gpg_gen"
bash ../scripts/gpg_gen.sh "kefu" "19157521820@163.com" "lkf.Gpg.mima3"

# ── CLI 工具 ──
info "安装 opencode..."
command -v opencode >/dev/null 2>&1 && skip "已存在" || curl -fsSL https://opencode.ai/install | bash

info "安装 zed..."
command -v zed >/dev/null 2>&1 && skip "已存在" || curl -f https://zed.dev/install.sh | sh
# ── SS 代理 ──
info "启动 SS 代理..."
bash ../scripts/ssProxyConfig.sh 202.182.112.91

# ── 系统包 ──
info "安装系统依赖..."
sudo pacman -Sy --needed --noconfirm base-devel yay keepassxc rust

rustup default stable
# ── AUR 包 ──
info "安装 AUR 包 (通过代理)..."
ALL_PROXY=socks5://127.0.0.1:1080 yay -S --needed --noconfirm cryptomator-bin clash-verge-rev-bin

# ── 启动应用 ──
info "启动应用..."
cryptomator &
clash-verge &
keepassxc &

ok "全部完成"
