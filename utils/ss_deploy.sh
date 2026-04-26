#!/bin/bash
# 用法: ./ss_deploy.sh <服务器IP> <密码> [配置名]
# 示例: ./ss_deploy.sh 202.182.112.91 mypassword tokyo

IP="${1:?需要服务器IP}"
PASSWORD="${2:?需要密码}"
CONFIG="${3:-config}"
SCRIPT=/data/.manjaro/utils/ss_server_conf.sh

# 1. 建立免密 SSH 认证
echo "🔑 配置免密登录..."
[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-keyscan -H "$IP" >> ~/.ssh/known_hosts 2>/dev/null
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@"$IP"

# 2. 上传并执行配置脚本
echo "📤 上传配置脚本..."
scp "$SCRIPT" root@"$IP":~/ss_server_conf.sh

echo "🚀 远程执行配置..."
ssh root@"$IP" "bash ss_server_conf.sh '$PASSWORD' 8388 aes-256-gcm '$CONFIG'"
