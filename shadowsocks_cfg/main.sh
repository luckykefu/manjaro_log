#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    local cmd="${1:-deploy}"

    case "$cmd" in
        deploy)
            local ip="${2:?'用法: main.sh deploy <ip> [port]'}"
            local port="${3:-8388}"
            ss_deploy "$ip" "$port"
            ;;
        server)
            local port="${2:-8388}"
            setup_ss_server "" "$port"
            ;;
        clash)
            local ip="${2:?'用法: main.sh clash <ip> [remote_cfg] [节点名] [输出文件]'}"
            local remote_cfg="${3:-/etc/shadowsocks-rust/config.json}"
            local node="${4:-SS节点}"
            local out="${5:-/tmp/clash_config.yaml}"
            clash_gen "$ip" "$remote_cfg" "$node" "$out"
            ;;
        *)
            err "用法: main.sh deploy <ip> [port]  |  main.sh server [port]  |  main.sh clash <ip> [remote_cfg] [节点名] [输出文件]"
            exit 1
            ;;
    esac
}

main "$@"
