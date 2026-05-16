TUNNEL_PID_FILE="/tmp/ssh-reverse-tunnel.pid"

tunnel_status() {
  [[ -f "$TUNNEL_PID_FILE" ]] || { echo "stopped"; return 1; }
  local pid; pid=$(cat "$TUNNEL_PID_FILE")
  kill -0 "$pid" 2>/dev/null && { echo "running ($pid)"; return 0; }
  echo "stale pid $pid"; return 1
}

tunnel_stop() {
  [[ -f "$TUNNEL_PID_FILE" ]] || { sinfo "tunnel not running"; return 0; }
  local pid; pid=$(cat "$TUNNEL_PID_FILE")
  kill "$pid" 2>/dev/null && sinfo "tunnel stopped (PID: $pid)" || true
  rm -f "$TUNNEL_PID_FILE"
}

tunnel_start() {
  local ip="$1" local_port="$2"

  tunnel_status > /dev/null 2>&1 && sinfo "tunnel already running ($(cat "$TUNNEL_PID_FILE"))" && return 0

  sinfo "[tunnel] establishing reverse tunnel: localhost:$local_port ← root@$ip:$local_port"
  ssh -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes \
    -N -R "${local_port}:localhost:22" "root@${ip}" &
  local pid=$!
  echo "$pid" > "$TUNNEL_PID_FILE"
  sinfo "  tunnel established (PID: $pid)"

  cat << INFO

====== SSH Reverse Proxy Ready ======
Remote access:
  ssh -p ${local_port} ${USER}@localhost
  scp -P ${local_port} file ${USER}@localhost:/path/
INFO
}
