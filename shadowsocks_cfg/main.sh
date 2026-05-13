#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
LIB_DIR="$SCRIPT_DIR/lib"

for lib in "$LIB_DIR"/*.sh; do
    source "$lib"
done

main() {
    case "${1:-deploy}" in
        deploy)  ss_deploy "${2:?'ip required'}" "${3:-8388}" ;;
        server)  setup_ss_server "" "${2:-8388}" ;;
        clash)   clash_gen "${2:?'ip required'}" "${3:-/etc/shadowsocks-rust/config.json}" "${4:-SS节点}" "${5:-/tmp/clash_config.yaml}" ;;
    esac
}

main "$@"
