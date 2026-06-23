#!/bin/bash
# sing-box 启停管理，支持按协议路由
# Usage: $0 {start|stop|restart|status} [ss|trojan|hy2|all|config_path]
set -u
SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
CMD=${1:-start}

resolve_cfg() {
    local arg="${1:-}"
    [[ -z "$arg" ]] && { echo "/etc/sing-box/config.json"; return; }
    [[ -f "$arg" ]] && { realpath -q "$arg" 2>/dev/null || echo "$arg"; return; }
    case "$arg" in
        ss|trojan|hy2|all|tun) echo "$SCRIPT_DIR/client-${arg}.json" ;;
        *)                 echo "$arg" ;;
    esac
}

CFG=$(resolve_cfg "${2:-}")
LOG=/var/log/sing-box.log
PIDFILE=/tmp/sing-box.pid

SUDO=""
[[ $EUID -ne 0 ]] && SUDO=sudo

read_pid() {
    if [[ -f "$PIDFILE" ]]; then
        $SUDO cat "$PIDFILE" 2>/dev/null
    fi
}

start() {
    local pid
    pid=$(read_pid)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "Already running (pid $pid)" >&2
        exit 1
    fi
    if [[ ! -f "$CFG" ]]; then
        echo "Config not found: $CFG" >&2
        exit 1
    fi
    $SUDO touch "$LOG" 2>/dev/null || $SUDO touch /tmp/sing-box.log
    LOGFILE=$LOG
    [[ ! -w "$LOGFILE" ]] && LOGFILE=/tmp/sing-box.log
    $SUDO nohup sing-box run -c "$CFG" > "$LOGFILE" 2>&1 &
    local spid=$!
    echo "$spid" | $SUDO tee "$PIDFILE" > /dev/null

    local ports
    ports=$($SUDO jq -r '.inbounds[] | select(.listen_port) | "\(.listen_port) \(.type)"' "$CFG" 2>/dev/null)
    for i in 1 2 3 4 5 6 7 8; do
        sleep 1
        kill -0 "$spid" 2>/dev/null || break
        local all_ok=true
        while IFS=' ' read -r port ptype; do
            if [[ "$ptype" == "hysteria2" || "$ptype" == "hysteria" ]]; then
                $SUDO ss -ulnp | grep -q ":$port " || all_ok=false
            else
                $SUDO ss -tlnp | grep -q ":$port " || all_ok=false
            fi
        done <<< "$ports"
        if $all_ok && [[ -n "$ports" ]]; then
            echo "Ports OK ($(echo "$ports" | tr '\n' ' '))"
            break
        fi
        if [[ $i -eq 8 ]]; then
            $SUDO ss -tlnp | grep -q "sing-box" || $SUDO ss -ulnp | grep -q "sing-box" \
                && echo "Port OK (partial)" || echo "Port check timeout"
        fi
    done
    if ! kill -0 "$spid" 2>/dev/null; then
        echo "Failed to start. Log:" >&2
        $SUDO cat "$LOG" >&2
        $SUDO rm -f "$PIDFILE"
        exit 1
    fi
    echo "Started (pid $spid, config: $CFG)"
    local mixed_port
    mixed_port=$($SUDO jq -r '.inbounds[] | select(.type == "mixed" and (.listen // "127.0.0.1" | test("^127\\.|^localhost$"))) | .listen_port // 1080' "$CFG" 2>/dev/null | head -1)
    if [[ -n "$mixed_port" ]]; then
        sleep 1
        local url="https://www.gstatic.com/generate_204"
        local code
        code=$(curl -x "http://127.0.0.1:$mixed_port" -4 -fsSL -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "FAIL")
        echo "Connectivity test ($url) : $code"
    fi
}

stop() {
    local pid
    pid=$(read_pid)
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && echo "Stopped (pid $pid)" || echo "Not running"
        $SUDO rm -f "$PIDFILE"
    else
        $SUDO pkill -x sing-box 2>/dev/null && echo "Stopped" || echo "Not running"
    fi
}

status() {
    local pid
    pid=$(read_pid)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "Running (pid $pid)"
        return
    fi
    local p
    p=$($SUDO pgrep -x sing-box 2>/dev/null || true)
    if [[ -n "$p" ]]; then
        echo "Running (pid $p, no pidfile)"
    else
        echo "Not running"
    fi
}

case "$CMD" in
    start)   start   ;;
    stop)    stop    ;;
    restart) stop; sleep 1; start ;;
    status)  status  ;;
    *)       echo "Usage: $0 {start|stop|restart|status} [ss|trojan|hy2|all|config_path]" >&2; exit 1 ;;
esac
