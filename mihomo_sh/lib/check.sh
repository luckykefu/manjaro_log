check() {
  local proxy_port="${1:-7897}" controller_port="${2:-9097}"

  sleep 2

  local node=""
  node=$(curl -s --connect-timeout 3 "http://127.0.0.1:${controller_port}/proxies/proxy" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('now','?'))" 2>/dev/null) || true

  local latency="" start code end
  start=$(date +%s%3N)
  code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 \
    -x "http://127.0.0.1:${proxy_port}" "http://www.gstatic.com/generate_204") || true
  end=$(date +%s%3N)

  [[ "$code" == "204" ]] && latency=$(( end - start ))

  if [[ -n "$node" && -n "$latency" ]]; then
    sinfo "[check] ✅ proxy working | node: $node | latency: ${latency}ms"
  elif [[ -n "$latency" ]]; then
    sinfo "[check] ✅ proxy reachable | latency: ${latency}ms"
  else
    swarn "[check] mihomo not ready, check: tail -f /tmp/mihomo.log"
    return 1
  fi

  for url in "https://www.google.com" "https://www.youtube.com" "https://github.com"; do
    local c s
    c=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 \
      -x "http://127.0.0.1:${proxy_port}" "$url" 2>/dev/null) || c="000"
    s="❌"; [[ "$c" == "200" || "$c" == "204" ]] && s="✅"
    sinfo "  $s $url → $c"
  done
}
