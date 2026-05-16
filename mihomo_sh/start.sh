#! /usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

start() {
    local dir="$1"
    nohup mihomo -d "$dir" > /tmp/mihomo.log 2>&1 & disown
    for _ in 1 2 3 4 5; do
        ss -tlnp 2>/dev/null | grep -q :7897 && break
        sleep 1
    done
    sleep 2
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        -x "http://127.0.0.1:7897" \
        "http://www.gstatic.com/generate_204") || true
    [[ "$code" != "204" ]] && return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    dir="${1:-$HOME/.config/mihomo}"
    start "$dir"
fi
