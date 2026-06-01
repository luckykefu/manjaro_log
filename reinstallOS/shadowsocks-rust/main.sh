#!/usr/bin/env bash
# main.sh — 一键完成：推公钥 → 部署服务端 → 配置客户端
set -euo pipefail

readonly IP="${1:?用法: $0 <VPS-IP>}"
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_ip "$IP"

echo "① 推送 SSH 公钥"
ssh_copy_id "$IP"

echo "② 部署服务端"
# lib.sh 一起传过去，server_deploy.sh 会 source 它
scp "$DIR/server_deploy.sh" "root@${IP}":~/
ssh "root@${IP}" "bash ~/server_deploy.sh"

echo "③ 配置本地客户端"
bash "$DIR/client_cfg.sh" "$IP"

echo "全部完成 ✓  SOCKS5 代理：127.0.0.1:1080"
