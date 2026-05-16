#! /usr/bin/env bash
# main.sh — SSH 反向代理: 密钥配置 + 隧道管理
# ========================================================
# 入参说明
# | 选项         | 默认值               | 说明            |
# |--------------|----------------------|-----------------|
# | --ip IP      | (必填)               | 远程服务器 IP    |
# | --key PATH   | ~/.ssh/id_ed25519    | 本地密钥路径     |
# | --port N     | 2223                 | 远程端口         |
# | --setup      | 仅配置密钥            |                 |
# | --start      | 仅启动隧道            |                 |
# | --stop       | 停止隧道              |                 |
# | --status     | 查看隧道状态          |                 |
# |              |                      |                 |
# | 默认(无action) | setup + start       |                 |
# ========================================================
# 处理逻辑:
#   setup: 本地密钥→清理host key→ssh-copy-id→远程密钥→互信
#   start: ssh -N -R <port>:localhost:22 root@<ip> (后台)
#   stop:  kill pid
#   status: 检查 pid 文件

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
PID_FILE="/tmp/ssh-reverse-tunnel.pid"

main() {
    local ip="" key="$HOME/.ssh/id_ed25519" port=2223 action="all"

    while [[ $# -gt 0 ]]; do case "$1" in
        --ip|-i)  ip="$2"; shift 2 ;; --key|-k) key="$2"; shift 2 ;;
        --port|-p) port="$2"; shift 2 ;;
        --setup) action="setup"; shift ;; --start) action="start"; shift ;;
        --stop) action="stop"; shift ;; --status) action="status"; shift ;;
        --help|-h) sed -n "4,13p" "$0"; exit 0 ;;
        *) echo "unknown: $1"; exit 1 ;;
    esac; done

    [[ -z "$ip" && "$action" != "stop" && "$action" != "status" ]] && { sed -n "4,13p" "$0"; exit 1; }

    case "$action" in
        setup)
            [[ ! -f "$key" ]] && ssh-keygen -t ed25519 -f "$key" -N ""
            ssh-keygen -R "$ip" 2>/dev/null || true
            ssh-copy-id -o StrictHostKeyChecking=accept-new -i "${key}.pub" "root@${ip}"
            ssh "root@${ip}" "[[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''"
            pub=$(ssh "root@${ip}" "cat ~/.ssh/id_ed25519.pub")
            mkdir -p ~/.ssh && chmod 700 ~/.ssh
            grep -qF "$pub" ~/.ssh/authorized_keys 2>/dev/null || echo "$pub" >> ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
            ;;

        start)
            [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && return 0
            ssh -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -N -R "${port}:localhost:22" "root@${ip}" &
            echo $! > "$PID_FILE"
            ;;

        stop)
            [[ -f "$PID_FILE" ]] || return 0
            kill "$(cat "$PID_FILE")" 2>/dev/null || true
            rm -f "$PID_FILE"
            ;;

        status)
            if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
                echo "running ($(cat "$PID_FILE"))"
            else
                echo "stopped"
                return 1
            fi
            ;;

        all)
            [[ ! -f "$key" ]] && ssh-keygen -t ed25519 -f "$key" -N ""
            ssh-keygen -R "$ip" 2>/dev/null || true
            ssh-copy-id -o StrictHostKeyChecking=accept-new -i "${key}.pub" "root@${ip}"
            ssh "root@${ip}" "[[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''"
            pub=$(ssh "root@${ip}" "cat ~/.ssh/id_ed25519.pub")
            mkdir -p ~/.ssh && chmod 700 ~/.ssh
            grep -qF "$pub" ~/.ssh/authorized_keys 2>/dev/null || echo "$pub" >> ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
            [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && return 0
            ssh -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -N -R "${port}:localhost:22" "root@${ip}" &
            echo $! > "$PID_FILE"
            ;;
    esac
}

main "$@"
