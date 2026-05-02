#!/bin/bash
# 远程部署 Shadowsocks 服务端，并启动本地客户端
# 用法: ss_deploy <ip> [port=8388]

set -euo pipefail

ss_deploy() {
    # $1: ip (必须), $2: port (可选, 默认8388)
    local IP="${1:?'ip is required'}"
    local PORT="${2:-8388}"
    local SCRIPT="$(dirname "$0")/ss_server_conf.sh"

    # 清除旧 host key
    ssh-keygen -R "$IP"

    # 配置免密登录
    echo "🔑 配置免密登录..."
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "root@$IP"

    # 上传配置脚本
    echo "📤 上传配置脚本..."
    scp "$SCRIPT" "root@$IP:~/ss_server_conf.sh"

    # 远程执行，密码自动生成
    echo "🚀 远程执行配置..."
    ssh "root@$IP" "bash ss_server_conf.sh '' '$PORT'"

    # 拉取配置并启动本地客户端
    echo "📲 启动本地客户端..."
    bash "$(dirname "$0")/ss_local.sh" "$IP"
}

ss_deploy "$@"
