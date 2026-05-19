#! /usr/bin/env bash
set -euo pipefail

start() {
    local dir="$1"
    local port
    port=$(sed -n 's/^mixed-port: *\([0-9]*\)/\1/p' "$dir/config.yaml")
    [[ -z "$port" ]] && port=7890

    setsid mihomo -d "$dir" > /tmp/mihomo.log 2>&1 &
    for _ in 1 2 3 4 5; do
        ss -tlnp 2>/dev/null | grep -q ":$port " && break
        sleep 1
    done
    sleep 2
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        -x "http://127.0.0.1:$port" \
        "http://www.gstatic.com/generate_204") || true
    [[ "$code" != "204" ]] && return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start "$(cd "$(dirname "$0")" && pwd)"
fi
