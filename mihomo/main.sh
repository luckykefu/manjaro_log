#! /usr/bin/env bash
# 安装
# 拉取配置
# 启动(pkill 先)
# 检测端口
# 检测连通性
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

url="${1:?Usage: $0 <subscribe-url>}"

sudo pacman -S --needed --noconfirm mihomo
curl -sLA 'clash.meta' -o config.yaml --connect-timeout 10 --max-time 30 "$url" || true
sudo pkill mihomo 2>/dev/null || true
setsid mihomo -d "$PWD" > /tmp/mihomo.log 2>&1 &

for _ in 1 2 3 4 5; do
  ss -tlnp 2>/dev/null | grep -q ":7890 " && break
  sleep 1
done
ss -tlnp 2>/dev/null | grep -q ":7890 " || { echo "port fail" >&2; exit 1; }

code=$(curl -sx http://127.0.0.1:7890 -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://www.gstatic.com/generate_204" || echo "")
[[ "$code" == "204" ]] && { echo ok; exit 0; } || { echo "connectivity fail (HTTP $code)" >&2; exit 1; }
