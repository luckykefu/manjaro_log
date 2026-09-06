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

deploy_server() {
    colab upload -s "$session" "$CSH" /content/shadowsocks_colab.sh
    colab exec -s "$session" <<< $'%%bash\nbash /content/shadowsocks_colab.sh'
}

get_colab_ip() {
    if [[ -n "$colab_ip" ]]; then
        echo "$colab_ip"
        return
    fi
    colab exec -s "$session" <<< $'%%bash\ntailscale ip -4' 2>/dev/null \
      | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'
}

pull_config() {
    local ip="$1" out="$2"
    ssh "root@${ip}" "cat $CFG" > "$out"
}

setup_local_client() {
    local ip="$1" tmpf="$2"
    sudo mkdir -p "$(dirname "$CFG")"
    jq --arg server "$ip" \
       --arg local_addr "$LOCAL_ADDR" \
       --argjson local_port "$LOCAL_PORT" \
       '.server = $server | .local_address = $local_addr | .local_port = $local_port' \
       "$tmpf" | sudo tee "$CFG" > /dev/null
    echo "本地配置: $CFG"

    sudo systemctl stop 'shadowsocks-rust@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
    sudo pkill -x ssservice 2>/dev/null || true
    sudo systemctl enable --now shadowsocks-rust@config.service
    sleep 1
}

verify() {
    sudo systemctl status shadowsocks-rust@config.service --no-pager -l 2>&1 | head -5
    ss -tlnp | grep ":${LOCAL_PORT} " || echo "警告: 端口 $LOCAL_PORT 未监听"
    echo ""
    echo "代理就绪: socks5h://${LOCAL_ADDR}:${LOCAL_PORT}"
    echo "测试: curl -x socks5h://${LOCAL_ADDR}:${LOCAL_PORT} https://ipinfo.io"
}

echo "=== 1. 上传并部署 SS 服务端 ==="
deploy_server

echo "=== 2. 获取 Colab IP ==="
colab_ip=$(get_colab_ip)
echo "Colab IP: $colab_ip"

echo "=== 3. 拉取服务端配置 ==="
tmpf=$(mktemp --suffix=.json)
trap "rm -f '$tmpf'" EXIT
pull_config "$colab_ip" "$tmpf"

echo "=== 4. 配置客户端并启动 ==="
setup_local_client "$colab_ip" "$tmpf"

echo "=== 5. 验证 ==="
verify
