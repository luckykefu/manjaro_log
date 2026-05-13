#!/bin/bash
# 远程部署 Shadowsocks 服务端，并启动本地客户端
# 用法: ss_deploy <ip> [port=8388]

set -euo pipefail

ss_deploy() {
    local IP="${1:?'ip is required'}"
    local PORT="${2:-8388}"
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local SCRIPT="${SCRIPT_DIR}/server.sh"

    ssh-keygen -R "$IP"

    echo "🔑 配置免密登录..."
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "root@$IP"

    echo "📤 上传配置脚本..."
    scp "$SCRIPT" "root@$IP:~/server.sh"

    echo "🚀 远程执行配置..."
    ssh "root@$IP" "bash server.sh '' '$PORT'"

    echo "📲 启动本地客户端..."
    bash "${SCRIPT_DIR}/proxy_config.sh" "$IP"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && ss_deploy "$@"
