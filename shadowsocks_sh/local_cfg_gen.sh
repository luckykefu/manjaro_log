#! /usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

local_cfg_gen() {
    local ip="" port="" password="" method="" template="local.example.json"

    while [[ $# -gt 0 ]]; do case "$1" in
        --server|-s) ip="$2"; shift 2 ;;
        --port|-p) port="${2:-8388}"; shift 2 ;;
        --password|-k) password="$2"; shift 2 ;;
        --method|-m) method="${2:-2022-blake3-aes-256-gcm}"; shift 2 ;;
        --template|-t) template="$2"; shift 2 ;;
        *) echo "unknown: $1"; exit 1 ;;
    esac; done

    [[ -z "$ip" || -z "$password" ]] && {
        echo "Usage: $0 --server IP --password KEY [--port PORT] [--method METHOD] [--template FILE]"
        exit 1
    }

    local out="${ip}.json"
    jq \
        --arg ip "$ip" \
        --arg port "${port:-8388}" \
        --arg pw "$password" \
        --arg method "${method:-2022-blake3-aes-256-gcm}" \
        '
            .server = $ip |
            .server_port = ($port | tonumber) |
            .password = $pw |
            .method = $method
        ' "$template" > "$out"

    echo "==> 已生成 ${out}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    local_cfg_gen "$@"
fi
