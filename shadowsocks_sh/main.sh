#! /usr/bin/env bash
# ========================================================
# shadowsocks_sh — AEAD-2022 Shadowsocks 一键管理
# ========================================================
# 用法:
#   ./main.sh install                 服务器部署+开机自启
#   ./main.sh start                   启动服务端
#   ./main.sh stop                    停止服务端
#   ./main.sh status                  查看状态
#   ./main.sh gencfg --ip IP --password KEY   生成本地客户端配置
#   ./main.sh client --ip IP          启动客户端 (读取 IP.json)
# ========================================================

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

source ./install.sh
source ./client_start.sh
source ./local_cfg_gen.sh

usage() {
    sed -n "3,12p" "$0"
    exit 0
}

main() {
    local cmd="${1:-}"
    [[ $# -eq 0 ]] && usage

    case "$cmd" in
        install)
            install
            ;;
        start)
            echo "==> 启动 ssserver..."
            sudo systemctl start ssserver-rust.service
            sudo systemctl status ssserver-rust.service --no-pager
            ;;
        stop)
            echo "==> 停止 ssserver..."
            sudo systemctl stop ssserver-rust.service
            echo "已停止"
            ;;
        status)
            echo "=== systemd ==="
            sudo systemctl status ssserver-rust.service --no-pager 2>&1 || true
            echo "=== 端口 8388 ==="
            ss -tlnp 2>/dev/null | grep 8388 || echo "未监听"
            ;;
        client)
            shift
            client_start "$@"
            ;;
        gencfg)
            shift
            local_cfg_gen "$@"
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "未知命令: $cmd"
            usage
            ;;
    esac
}

main "$@"
