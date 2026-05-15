#!/usr/bin/env bash

## Brief: Check mihomo service and port 7890 connectivity
cmd_check() {
  local svc_ok=false port_ok=false

  if systemctl is-active --quiet mihomo 2>/dev/null; then
    info "mihomo service is running"
    svc_ok=true
  else
    warn "mihomo service is NOT running"
  fi

  if curl -fsSL --connect-timeout 5 --max-time 10 \
    --proxy http://127.0.0.1:7890 \
    -o /dev/null http://www.gstatic.com/generate_204 2>/dev/null; then
    info "Port 7890 (mixed proxy) is reachable"
    port_ok=true
  else
    warn "Port 7890 (mixed proxy) is NOT reachable"
  fi

  if $svc_ok && $port_ok; then
    info "All checks passed"
    return 0
  else
    warn "Some checks failed"
    return 1
  fi
}
