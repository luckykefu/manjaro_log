#! /usr/bin/env bash
set -euo pipefail

start() {
    local dir="$1"
    local port
    port=$(sed -n 's/^mixed-port: *\([0-9]*\)/\1/p' "$dir/config.yaml")
    [[ -z "$port" ]] && port=7890

    echo "==> 启动 mihomo..."
    setsid mihomo -d "$dir" > /tmp/mihomo.log 2>&1 &
    for _ in 1 2 3 4 5; do
        ss -tlnp 2>/dev/null | grep -q ":$port " && break
        sleep 1
    done

    if ! ss -tlnp 2>/dev/null | grep -q ":$port "; then
        echo "==> 错误: mihomo 未在端口 ${port} 上监听"
        tail -20 /tmp/mihomo.log 2>/dev/null || true
        return 1
    fi
    echo "==> mihomo 已监听 ${port} 端口"

    sleep 2
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        -x "http://127.0.0.1:$port" \
        "http://www.gstatic.com/generate_204") || true
    if [[ "$code" != "204" ]]; then
        echo "==> 警告: 连通性检测失败 (HTTP $code)，但 mihomo 已运行"
        tail -20 /tmp/mihomo.log 2>/dev/null || true
        return 1
    fi
    echo "==> 连通性检测通过"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start "$(cd "$(dirname "$0")" && pwd)"
fi
