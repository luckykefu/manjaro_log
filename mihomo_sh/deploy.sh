#! /usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

deploy() {
    local url="$1"
    sudo pacman -S --needed --noconfirm archlinuxcn/mihomo

    echo "==> 通过 shadowsocks 代理下载订阅配置..."
    curl -sx socks5://127.0.0.1:1080 \
        -A 'clash.meta' \
        -o config.yaml "$url"

    echo "==> 订阅配置已保存到 $PWD/config.yaml"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ $# -lt 1 ]] && { echo "Usage: $0 <url>"; exit 1; }
    deploy "$@"
fi
