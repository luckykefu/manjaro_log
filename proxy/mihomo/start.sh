#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")" || exit 1

readonly CONFIG="config.yaml"
[[ -f $CONFIG ]] || { echo "错误: $CONFIG 不存在于 $(pwd)" >&2; exit 1; }

readonly PORT=$(yq -r '.["mixed-port"] // 7890' "$CONFIG" 2>/dev/null || echo 7890)
readonly LOG="mihomo.log"

stop() {
    sudo pkill -x mihomo 2>/dev/null || true
    for i in 1 2 3 4 5; do
        pgrep -x mihomo >/dev/null 2>&1 || { echo "已停止"; return 0; }
        sleep 1
    done
    echo "警告: 强制终止" >&2
    sudo pkill -9 -x mihomo 2>/dev/null || true
}

start() {
    local tun=${1:-false}
    stop

    [[ $tun = true ]] && {
        yq -iy '.tun = {"enable": true, "stack": "mixed", "dns-hijack": ["any:53"], "auto-route": true, "auto-redirect": true, "auto-detect-interface": true}' "$CONFIG"
        echo "TUN 已启用"
    }

    [[ $tun = false ]] && {
        yq -iy '.tun.enable = false' "$CONFIG"
        echo "TUN 已关闭"
    }

    nohup sudo mihomo -d "$(pwd)" > "$LOG" 2>&1 &
    local pid=$!

    local i
    for i in 1 2 3 4 5 6 7 8; do
        if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            echo "端口 $PORT 已监听 (PID $pid)"
            local code
            code=$(curl -sx "http://127.0.0.1:$PORT" -o /dev/null -w "%{http_code}" \
                --connect-timeout 5 --max-time 10 \
                "https://www.gstatic.com/generate_204" 2>/dev/null || echo "000")
            [[ $code = 204 ]] && {
                echo "✓ 代理正常 (HTTP 204)"
                return 0
            } || {
                echo "✗ 代理连通性异常 (HTTP $code)" >&2
                return 1
            }
        fi
        sleep 1
    done

    echo "错误: 端口 $PORT 启动超时 (8s)" >&2
    return 1
}

case "${1:-}" in
    stop)   stop ;;
    status)
        pid=$(pgrep -x mihomo 2>/dev/null) && echo "运行中 PID $pid" || echo "未运行"
        ;;
    --tun)  start true ;;
    *)      start false ;;
esac
