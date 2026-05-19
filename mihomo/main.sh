#! /usr/bin/env bash
# main.sh — mihomo 一站式配置
# ========================================================
# 入参说明
# | 选项             | 默认值 | 说明    |
# |------------------|--------|---------|
# | --subscribe URL  | (必填)  | 订阅链接 |
# |                  |        |         |
# | 返回 0           | 成功   |         |
# | 返回 1           | 失败   |         |
# ========================================================
# 处理逻辑:
#   sudo pacman -S mihomo
#   ↓
#   curl 订阅 → config.yaml (走 shadowsocks 代理下载)
#   ↓
#   nohup mihomo -d .
#   ↓
#   curl gstatic → 检测连通性

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

source ./deploy.sh
source ./start.sh

main() {
    local url=""

    while [[ $# -gt 0 ]]; do case "$1" in
        --subscribe|-s) url="$2"; shift 2 ;;
        --help|-h) sed -n "4,7p" "$0"; exit 0 ;;
        *) echo "unknown: $1"; exit 1 ;;
    esac; done

    [[ -z "$url" ]] && { sed -n "4,7p" "$0"; exit 1; }

    deploy "$url"
    start "$PWD"
}

main "$@"
