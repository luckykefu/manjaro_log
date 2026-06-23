#!/usr/bin/env bash
set -euo pipefail

# ============ 配置加载 ============

cd "$(dirname "$0")" || exit 1

readonly CONFIG="config.yaml"
[[ -f $CONFIG ]] || { echo "错误: $CONFIG 不存在于 $(pwd)" >&2; exit 1; }

readonly PORT=$(yq -r '.["mixed-port"] // 7890' "$CONFIG" 2>/dev/null || echo 7890)
readonly LOG="mihomo.log"

# ============ 辅助函数 ============

stop() {
    sudo pkill -x mihomo 2>/dev/null || true
    for i in 1 2 3 4 5; do
        pgrep -x mihomo >/dev/null 2>&1 || { echo "已停止"; return 0; }
        sleep 1
    done
    echo "警告: 强制终止" >&2
    sudo pkill -9 -x mihomo 2>/dev/null || true
}

fix_tun_route() {
    local FIP
    FIP=$(yq -r '.dns.fake-ip-range // "198.18.0.1/16"' "$CONFIG" 2>/dev/null || echo "198.18.0.1/16")
    sudo ip rule add to "$FIP" lookup 2022 pref 8999 2>/dev/null || true
    echo "TUN 路由规则已修复 ($FIP)"
}

health_check() {
    local wait=0
    while [[ $wait -lt 120 ]]; do
        local code
        code=$(curl -sx "http://127.0.0.1:$PORT" -o /dev/null -w "%{http_code}" \
            --connect-timeout 5 --max-time 10 \
            "https://www.google.com/generate_204" 2>/dev/null || echo "000")
        [[ $code = 204 ]] && { echo "✓ 代理正常 (HTTP 204)"; return 0; }
        sleep 20
        wait=$((wait + 20))
    done
    echo "✗ 代理连通性异常 (HTTP $code)" >&2
    return 1
}

# ============ 启动流程 ============

start() {
    local tun=${1:-false}
    stop

    # ── Phase 1: 配置预处理 ──

    if [[ $tun = true ]]; then
        yq -iy '.tun = {"enable": true, "stack": "mixed", "dns-hijack": ["any:53"], "auto-route": true, "auto-redirect": true, "auto-detect-interface": true, "exclude-interface": ["tailscale0"], "include-uid": [1000]}' "$CONFIG"
        echo "TUN 已启用"
    else
        yq -iy '.tun.enable = false' "$CONFIG"
        echo "TUN 已关闭"
    fi

    yq -iy '."proxy-groups" |= map(if .name == "🐮牛逼" then .type = "url-test" | .url = "https://www.google.com/generate_204" | .interval = 300 | .tolerance = 50 else . end)' "$CONFIG"
    echo "🐮牛逼 组已设为 url-test"

    # ── Phase 2: 启动 mihomo ──

    nohup sudo mihomo -d "$(pwd)" > "$LOG" 2>&1 &
    local pid=$!

    # ── Phase 3: 等待端口就绪 ──

    local i
    for i in 1 2 3 4 5 6 7 8; do
        if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            echo "端口 $PORT 已监听 (PID $pid)"
            break
        fi
        sleep 2
    done
    if ! ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
        echo "错误: 端口 $PORT 启动超时 (8s)" >&2
        return 1
    fi

    # ── Phase 4: 后处理 ──

    [[ $tun = true ]] && fix_tun_route

    # ── Phase 5: 连通性检测 ──

    health_check
}

# ============ 入口 ============

case "${1:-}" in
    stop)   stop ;;
    status)
        pid=$(pgrep -x mihomo 2>/dev/null) && echo "运行中 PID $pid" || echo "未运行"
        ;;
    --tun)  start true ;;
    *)      start false ;;
esac
