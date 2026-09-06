#!/usr/bin/env bash
# 部署 WG 服务端到 VPS
set -euo pipefail

ip="${1:?用法: $0 <vps-ip>}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scp "$dir/server.sh" "root@$ip":/tmp/
ssh "root@$ip" "bash /tmp/server.sh"
