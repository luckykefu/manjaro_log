#!/bin/bash
set -euo pipefail
# 切换到脚本目录（原注释未实现，现改为切换到脚本所在目录）
cd "$(dirname "$0")" || exit 1
# 安装 mihomo
sudo pacman -S --needed --noconfirm mihomo yq &> /dev/null

# 拉取配置
readonly url=${1:?URL???}
readonly CONFIG="config.yaml"
[[ ! -f "$CONFIG" ]] \
    && curl -sLfA 'clash.meta' --connect-timeout 10 --max-time 30 --retry 2 -o "$CONFIG" "$url" \
    || echo "$CONFIG exist"
