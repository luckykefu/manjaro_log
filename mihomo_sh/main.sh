#! /usr/bin/env bash
# main.sh — mihomo 一站式配置
# ========================================================
# 入参说明
# | 选项             | 默认值             | 说明        |
# |------------------|--------------------|-------------|
# | --subscribe URL  | (必填)             | 订阅链接     |
# | --output DIR     | ~/.config/mihomo   | 配置输出目录 |
# | --nameserver IP  | 223.5.5.5          | DNS          |
# |                  |                    |             |
# | 返回 0           | 成功               |             |
# | 返回 1           | 失败               |             |
# ========================================================
# 处理逻辑:
#   sudo pacman -S mihomo
#   ↓
#   写入 config.yaml (proxy-providers type: http)
#   ↓
#   nohup mihomo -d (mihomo 自动拉取订阅)
#   ↓
#   curl gstatic → 检测连通性

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

source ./deploy.sh
source ./start.sh

main() {
    local url="" dir="$HOME/.config/mihomo" ns="223.5.5.5"

    while [[ $# -gt 0 ]]; do case "$1" in
        --subscribe|-s) url="$2"; shift 2 ;;
        --output|-o) dir="$2"; shift 2 ;;
        --nameserver) ns="$2"; shift 2 ;;
        --help|-h) sed -n "4,9p" "$0"; exit 0 ;;
        *) echo "unknown: $1"; exit 1 ;;
    esac; done

    [[ -z "$url" ]] && { sed -n "4,9p" "$0"; exit 1; }

    deploy "$url" "$dir" "$ns"
    start "$dir"
}

main "$@"
