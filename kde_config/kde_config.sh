#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."  # 确保在脚本目录下执行
ALL_PROXY=socks5://127.0.0.1:1080 bash scripts/install_mac_themes.sh
kcmshell6 kcm_lookandfeel
bash scripts/009_config_kde_clock.sh
bash scripts/010_config_kde_wallpaper.sh
bash scripts/013_cfg_kde.sh
