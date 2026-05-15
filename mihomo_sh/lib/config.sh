#!/usr/bin/env bash

## Brief: Generate mihomo config.yaml from subscription
##        Downloads subscription, parses proxies, writes YAML config
cmd_gen() {
  local output="${MIHOMO_CONFIG:-/etc/mihomo/config.yaml}"
  local proxies_tmp proxies=()
  local parsed_lines

  info "Step 1: Downloading subscription"
  cmd_subscribe

  info "Step 2: Parsing proxies"
  parsed_lines=$(parse_proxies)

  local gen_proxies=()
  local gen_auto=()
  local gen_select=()
  local idx=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local name proxy_str
    name=$(proxy_name_from_parsed "$line" "$idx")
    proxy_str=$(parsed_to_mihomo_entry "$line" "$name")
    gen_proxies+=("$proxy_str")
    gen_auto+=("$name")
    gen_select+=("$name")
    idx=$((idx + 1))
  done <<< "$parsed_lines"

  [[ ${#gen_proxies[@]} -gt 0 ]] || die "No valid proxies parsed from subscription"

  info "Step 3: Generating config with ${#gen_proxies[@]} proxies"

  local config_dir
  config_dir=$(dirname "$output")
  if [[ ! -d "$config_dir" ]]; then
    info "Creating directory $config_dir"
    mkdir -p "$config_dir"
  fi

  {
    printf '%s\n' "port: 7890"
    printf '%s\n' "socks-port: 7891"
    printf '%s\n' "mixed-port: 7890"
    printf '%s\n' "external-controller: 0.0.0.0:9090"
    printf '%s\n' "log-level: info"
    printf '%s\n' "allow-lan: true"
    printf '%s\n' "mode: rule"
    printf '%s\n' ""

    printf '%s\n' "proxies:"
    for entry in "${gen_proxies[@]}"; do
      echo "$entry"
    done
    printf '%s\n' ""

    printf '%s\n' "proxy-groups:"
    printf '%s\n' "  - name: Auto"
    printf '%s\n' "    type: url-test"
    printf '%s\n' "    url: http://www.gstatic.com/generate_204"
    printf '%s\n' "    interval: 300"
    printf '%s\n' "    proxies:"
    for p in "${gen_auto[@]}"; do
      printf '      - %s\n' "$p"
    done

    printf '%s\n' ""
    printf '  - name: Proxy\n'
    printf '%s\n' "    type: select"
    printf '%s\n' "    proxies:"
    for p in "${gen_select[@]}"; do
      printf '      - %s\n' "$p"
    done
    printf '      - Auto\n'
    printf '      - DIRECT\n'
    printf '%s\n' ""

    printf '%s\n' "rules:"
    printf '%s\n' "  - MATCH,Proxy"
  } > "$output"

  info "Config written to $output"
}

## Brief: Generate a proxy name from parsed line and index
## Args: $1 - parsed line, $2 - index number
proxy_name_from_parsed() {
  local parsed=$1 idx=$2 type
  type="${parsed%%$'\t'*}"
  case "$type" in
    vless)   printf "vless-%d" "$idx" ;;
    anytls)  printf "anytls-%d" "$idx" ;;
    tuic)    printf "tuic-%d" "$idx" ;;
    hysteria2) printf "hy2-%d" "$idx" ;;
    vmess)   printf "vmess-%d" "$idx" ;;
    *)       printf "proxy-%d" "$idx" ;;
  esac
}

## Brief: Convert parsed proxy line to mihomo YAML entry
## Args: $1 - parsed line, $2 - proxy name
parsed_to_mihomo_entry() {
  local parsed=$1 name=$2 type rest
  type="${parsed%%$'\t'*}"
  rest="${parsed#*$'\t'}"

  _get_field() {
    local f=$1 field
    while IFS=$'\t' read -ra fields; do
      for field in "${fields[@]}"; do
        if [[ "$field" == "$f="* ]]; then
          echo "${field#*=}"
          return
        fi
      done
    done <<< "$rest"
  }

  case "$type" in
    vless)
      local server port uuid flow encryption security sni fingerprint publicKey shortId spx
      server=$(_get_field server)
      port=$(_get_field port)
      uuid=$(_get_field id)
      flow=$(_get_field flow)
      encryption=$(_get_field encryption)
      security=$(_get_field security)
      sni=$(_get_field sni)
      fingerprint=$(_get_field fingerprint)
      publicKey=$(_get_field publicKey)
      shortId=$(_get_field shortId)
      spx=$(_get_field spx)
      [[ -z "$security" ]] && security="none"
      cat <<YEOF
  - name: $name
    type: vless
    server: $server
    port: $port
    uuid: $uuid
    flow: $flow
    tls: true
    servername: $sni
    fingerprint: $fingerprint
    reality-opts:
      public-key: $publicKey
      short-id: $shortId
YEOF
      ;;
    anytls)
      local server port password sni
      server=$(_get_field server)
      port=$(_get_field port)
      password=$(_get_field password)
      sni=$(_get_field sni)
      cat <<YEOF
  - name: $name
    type: anytls
    server: $server
    port: $port
    password: $password
    servername: $sni
YEOF
      ;;
    tuic)
      local server port password uuid congestion_control sni alpn udp_relay_mode
      server=$(_get_field server)
      port=$(_get_field port)
      password=$(_get_field password)
      uuid=$(_get_field uuid)
      congestion_control=$(_get_field congestion_control)
      sni=$(_get_field sni)
      alpn=$(_get_field alpn)
      udp_relay_mode=$(_get_field udp_relay_mode)
      [[ -z "$congestion_control" ]] && congestion_control="bbr"
      cat <<YEOF
  - name: $name
    type: tuic
    server: $server
    port: $port
    token: $password
    uuid: $uuid
    congestion-controller: $congestion_control
    udp-relay-mode: $udp_relay_mode
    udp-over-stream: false
    servername: $sni
    alpn:
      - $alpn
YEOF
      ;;
    hysteria2)
      local server port password sni alpn download_bandwidth up down
      server=$(_get_field server)
      port=$(_get_field port)
      password=$(_get_field password)
      sni=$(_get_field sni)
      alpn=$(_get_field alpn)
      download_bandwidth=$(_get_field download_bandwidth)
      up=$(_get_field up)
      down=$(_get_field down)
      local hy_dl="$download_bandwidth"
      [[ -z "$hy_dl" && -n "$down" ]] && hy_dl="$down"
      cat <<YEOF
  - name: $name
    type: hysteria2
    server: $server
    port: $port
    password: $password
    servername: $sni
    alpn:
      - $alpn
    download-bandwidth: $hy_dl
YEOF
      ;;
    vmess)
      local t ype uuid server port cipher network ws_path sni alpn tls fingerprint publicKey shortId spx ws_h_host ws_h_key
      t=$(_get_field type)
      uuid=$(_get_field uuid)
      server=$(_get_field server)
      port=$(_get_field port)
      cipher=$(_get_field cipher)
      network=$(_get_field network)
      ws_path=$(_get_field "ws-path")
      sni=$(_get_field sni)
      alpn=$(_get_field alpn)
      tls_flag=$(_get_field tls)
      fingerprint=$(_get_field fingerprint)
      publicKey=$(_get_field publicKey)
      shortId=$(_get_field shortId)
      spx=$(_get_field spx)
      ws_h_host=$(_get_field "ws-headers-Host")
      ws_h_key=$(_get_field "ws-headers-Key")

      local tls_str="false"
      if [[ "$tls_flag" == "tls" ]]; then
        tls_str="true"
      fi

      printf '  - name: %s\n' "$name"
      printf '    type: vmess\n'
      printf '    server: %s\n' "$server"
      printf '    port: %s\n' "$port"
      printf '    uuid: %s\n' "$uuid"
      printf '    alter-id: 0\n'
      printf '    cipher: %s\n' "$cipher"
      printf '    udp: true\n'
      printf '    tls: %s\n' "$tls_str"
      if [[ "$tls_flag" == "tls" && -n "$sni" ]]; then
        printf '    servername: %s\n' "$sni"
      fi
      if [[ "$tls_flag" == "tls" && -n "$fingerprint" ]]; then
        printf '    fingerprint: %s\n' "$fingerprint"
      fi
      if [[ "$tls_flag" == "tls" && -n "$publicKey" ]]; then
        printf '    reality-opts:\n'
        printf '      public-key: %s\n' "$publicKey"
        printf '      short-id: %s\n' "$shortId"
      fi
      printf '    network: %s\n' "$network"
      if [[ "$network" == "ws" && -n "$ws_path" ]]; then
        printf '    ws-opts:\n'
        printf '      path: %s\n' "$ws_path"
        if [[ -n "$ws_h_host" || -n "$ws_h_key" ]]; then
          printf '      headers:\n'
          [[ -n "$ws_h_host" ]] && printf '        Host: %s\n' "$ws_h_host"
          [[ -n "$ws_h_key" ]] && printf '        Key: %s\n' "$ws_h_key"
        fi
      fi
      if [[ -n "$alpn" ]]; then
        printf '    alpn:\n      - %s\n' "$alpn"
      fi
      ;;
  esac
}
