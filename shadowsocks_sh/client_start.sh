#! /usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

client_start() {
    local ip="" port="" password="" method="" local_addr="" local_port=""

    while [[ $# -gt 0 ]]; do case "$1" in
        --ip|-i) ip="$2"; shift 2 ;;
        --port|-p) port="$2"; shift 2 ;;
        --password|-k) password="$2"; shift 2 ;;
        --method|-m) method="$2"; shift 2 ;;
        --local-addr|-b) local_addr="$2"; shift 2 ;;
        --local-port|-l) local_port="$2"; shift 2 ;;
        *) echo "unknown: $1"; exit 1 ;;
    esac; done

    [[ -z "$ip" ]] && { echo "错误: --ip 是必需参数"; exit 1; }

    local cfg="${ip}.json"
    [[ ! -f "$cfg" ]] && { echo "不存在: $cfg。先运行 ./main.sh gencfg"; exit 1; }

    local tmp
    tmp=$(mktemp)
    jq \
        --arg ip "$ip" \
        --arg port "${port:-$(jq -r '.server_port // "8388"' "$cfg")}" \
        --arg pw "${password:-$(jq -r '.password // empty' "$cfg")}" \
        --arg m "${method:-$(jq -r '.method // "2022-blake3-aes-256-gcm"' "$cfg")}" \
        --arg la "${local_addr:-$(jq -r '.local_address // "127.0.0.1"' "$cfg")}" \
        --arg lp "${local_port:-$(jq -r '.local_port // "1080"' "$cfg")}" \
        '{
            server: $ip,
            server_port: ($port | tonumber),
            password: $pw,
            method: $m,
            local_address: $la,
            local_port: ($lp | tonumber)
        }' <<< '{}' > "$tmp"

    echo "==> sslocal → $ip:$(jq -r '.server_port' "$tmp")  → SOCKS5 $(jq -r '.local_address' "$tmp"):$(jq -r '.local_port' "$tmp")"
    nohup sslocal -c "$tmp" > /tmp/sslocal.log 2>&1 & disown

    for _ in 1 2 3 4 5; do
        ss -tlnp 2>/dev/null | grep -q ":$(jq -r '.local_port' "$tmp")" && break
        sleep 1
    done

    echo "==> 已启动"
    rm -f "$tmp"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    client_start "$@"
fi
