start() {
  local output_dir="$1"
  local pid_file="${output_dir}/mihomo.pid"

  if [[ -f "$pid_file" ]]; then
    local old_pid; old_pid=$(cat "$pid_file")
    kill -0 "$old_pid" 2>/dev/null && sinfo "[start] mihomo already running (PID: $old_pid)" && return 0
    rm -f "$pid_file"
  fi

  mkdir -p "$output_dir"
  nohup mihomo -d "$output_dir" > /tmp/mihomo.log 2>&1 & disown
  local pid=$!
  echo "$pid" > "$pid_file"
  sinfo "[start] mihomo started (PID: $pid)"

  for _ in 1 2 3 4 5; do
    ss -tlnp 2>/dev/null | grep -q ':7897' && sinfo "[start] mihomo ready (port 7897)" && return 0
    sleep 1
  done

  swarn "[start] mihomo may not be ready, check: tail -f /tmp/mihomo.log"
  return 1
}
