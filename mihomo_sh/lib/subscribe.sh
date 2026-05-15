#!/usr/bin/env bash

## Brief: Download subscription from URL and save to /tmp/mihomo-sub.txt
## Args: $1 - subscription URL (optional, falls back to CONFIG_URL env var)
cmd_subscribe() {
  local url="${1:-${CONFIG_URL:-}}"
  [[ -n "$url" ]] || die "No subscription URL provided. Set CONFIG_URL or pass as argument."

  info "Downloading subscription from ${url}"
  curl -fsSL --connect-timeout 15 --max-time 60 "$url" -o /tmp/mihomo-sub.txt || die "Failed to download subscription"

  local size
  size=$(wc -c < /tmp/mihomo-sub.txt)
  info "Saved subscription to /tmp/mihomo-sub.txt (${size} bytes)"
}
