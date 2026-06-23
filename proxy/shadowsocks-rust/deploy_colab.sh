#!/usr/bin/env bash
# 一键部署 SS 服务端（Colab）并启动本地客户端
set -euo pipefail

readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CSH="$DIR/shadowsocks_colab.sh"
readonly CFG=/etc/shadowsocks-rust/config.json
readonly LOCAL_ADDR="127.0.0.1"
readonly LOCAL_PORT=1080

session="${1:?用法: $0 <colab-session> [colab-ip]}"
colab_ip="${2:-}"

echo "=== 1. 上传脚本到 Colab ==="
colab upload -s "$session" "$CSH" /content/shadowsocks_colab.sh

echo "=== 2. 部署 SS 服务端 ==="
colab exec -s "$session" <<< $'%%bash\nbash /content/shadowsocks_colab.sh'

echo "=== 3. 获取 Colab tailscale IP ==="
if [[ -z "$colab_ip" ]]; then
    colab_ip=$(colab exec -s "$session" <<< $'%%bash\ntailscale ip -4' 2>/dev/null \
      | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
fi
echo "Colab IP: $colab_ip"

echo "=== 4. 拉取服务端配置 ==="
tmpf=$(mktemp --suffix=.json)
trap "rm -f '$tmpf'" EXIT

ssh "root@${colab_ip}" "cat $CFG" > "$tmpf"

echo "=== 5. 生成本地客户端配置 ==="
sudo mkdir -p "$(dirname "$CFG")"
jq --arg server "$colab_ip" \
   --arg local_addr "$LOCAL_ADDR" \
   --argjson local_port "$LOCAL_PORT" \
   '.server = $server | .local_address = $local_addr | .local_port = $local_port' \
   "$tmpf" | sudo tee "$CFG" > /dev/null
echo "本地配置: $CFG"

echo "=== 6. 启动本地客户端 ==="
sudo systemctl stop 'shadowsocks-rust@*' 2>/dev/null || true
sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
sudo pkill -x ssservice 2>/dev/null || true
sudo systemctl enable --now shadowsocks-rust@config.service
sleep 1

echo "=== 7. 验证 ==="
sudo systemctl status shadowsocks-rust@config.service --no-pager -l 2>&1 | head -5
ss -tlnp | grep ":${LOCAL_PORT} " || echo "警告: 端口 $LOCAL_PORT 未监听"
echo ""

echo "代理就绪: socks5h://${LOCAL_ADDR}:${LOCAL_PORT}"
echo "测试: curl -x socks5h://${LOCAL_ADDR}:${LOCAL_PORT} https://ipinfo.io"
