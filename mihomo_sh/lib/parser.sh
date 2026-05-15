#!/usr/bin/env bash

## Brief: Decode base64 subscription and parse each proxy URI line
##        Supports vless://, anytls://, tuic://, hysteria2://, vmess://
## Args: $1 - path to subscription file (default: /tmp/mihomo-sub.txt)
## Output: Tab-separated lines: TYPE field1=val1 field2=val2 ...
parse_proxies() {
  local sub_file="${1:-/tmp/mihomo-sub.txt}"
  local decoded
  local proxies=()

  [[ -f "$sub_file" ]] || die "Subscription file not found: $sub_file"

  decoded=$(base64 -d < "$sub_file" 2>/dev/null) || die "Failed to base64-decode subscription"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    proxies+=("$line")
  done <<< "$decoded"

  [[ ${#proxies[@]} -gt 0 ]] || die "No proxy entries found after decoding"

  for uri in "${proxies[@]}"; do
    case "$uri" in
      vless://*)
        parse_vless "$uri"
        ;;
      anytls://*)
        parse_anytls "$uri"
        ;;
      tuic://*)
        parse_tuic "$uri"
        ;;
      hysteria2://*)
        parse_hysteria2 "$uri"
        ;;
      vmess://*)
        parse_vmess "$uri"
        ;;
      *)
        warn "Unknown proxy type, skipping: ${uri:0:60}..."
        ;;
    esac
  done
}

## Brief: Parse vless:// URI
## Args: $1 - vless URI
parse_vless() {
  local uri=$1 stripped query id server port flow encryption security sni fingerprint publicKey shortId spx
  stripped="${uri#vless://}"
  query="${stripped#*[?]}"
  stripped="${stripped%%[?]*}"
  id="${stripped%%@*}"
  stripped="${stripped#*@}"
  server="${stripped%:*}"
  port="${stripped##*:}"

  flow=""; encryption=""; security=""; sni=""; fingerprint=""; publicKey=""; shortId=""; spx=""
  for pair in ${query//&/ }; do
    case "$pair" in
      flow=*) flow="${pair#flow=}" ;;
      encryption=*) encryption="${pair#encryption=}" ;;
      security=*) security="${pair#security=}" ;;
      sni=*) sni="${pair#sni=}" ;;
      fingerprint=*) fingerprint="${pair#fingerprint=}" ;;
      publicKey=*) publicKey="${pair#publicKey=}" ;;
      shortId=*) shortId="${pair#shortId=}" ;;
      spx=*) spx="${pair#spx=}" ;;
    esac
  done

  printf "vless\tid=%s\tserver=%s\tport=%s\tflow=%s\tencryption=%s\tsecurity=%s\tsni=%s\tfingerprint=%s\tpublicKey=%s\tshortId=%s\tspx=%s\n" \
    "$id" "$server" "$port" "$flow" "$encryption" "$security" "$sni" "$fingerprint" "$publicKey" "$shortId" "$spx"
}

## Brief: Parse anytls:// URI
## Args: $1 - anytls URI
parse_anytls() {
  local uri=$1 stripped query server port password sni chain
  stripped="${uri#anytls://}"
  query="${stripped#*[?]}"
  stripped="${stripped%%[?]*}"
  password="${stripped%%@*}"
  stripped="${stripped#*@}"
  server="${stripped%:*}"
  port="${stripped##*:}"
  [[ "$port" == *[?]* ]] && port="${port%%[?]*}"

  sni=""; chain=""
  for pair in ${query//&/ }; do
    case "$pair" in
      sni=*) sni="${pair#sni=}" ;;
      chain=*) chain="${pair#chain=}" ;;
    esac
  done

  printf "anytls\tserver=%s\tport=%s\tpassword=%s\tsni=%s\tchain=%s\n" \
    "$server" "$port" "$password" "$sni" "$chain"
}

## Brief: Parse tuic:// URI
## Args: $1 - tuic URI
parse_tuic() {
  local uri=$1 stripped query server port password uuid congestion_control sni alpn udp_relay_mode
  stripped="${uri#tuic://}"
  query="${stripped#*[?]}"
  stripped="${stripped%%[?]*}"
  password="${stripped%%@*}"
  stripped="${stripped#*@}"
  server="${stripped%:*}"
  port="${stripped##*:}"
  [[ "$port" == *[?]* ]] && port="${port%%[?]*}"

  uuid="$password"; congestion_control=""; sni=""; alpn=""; udp_relay_mode=""
  for pair in ${query//&/ }; do
    case "$pair" in
      congestion_control=*) congestion_control="${pair#congestion_control=}" ;;
      sni=*) sni="${pair#sni=}" ;;
      alpn=*) alpn="${pair#alpn=}" ;;
      udp_relay_mode=*) udp_relay_mode="${pair#udp_relay_mode=}" ;;
    esac
  done

  printf "tuic\tserver=%s\tport=%s\tpassword=%s\tuuid=%s\tcongestion_control=%s\tsni=%s\talpn=%s\tudp_relay_mode=%s\n" \
    "$server" "$port" "$password" "$uuid" "$congestion_control" "$sni" "$alpn" "$udp_relay_mode"
}

## Brief: Parse hysteria2:// URI
## Args: $1 - hysteria2 URI
parse_hysteria2() {
  local uri=$1 stripped query server port password sni alpn download_bandwidth up down
  stripped="${uri#hysteria2://}"
  query="${stripped#*[?]}"
  stripped="${stripped%%[?]*}"
  password="${stripped%%@*}"
  stripped="${stripped#*@}"
  server="${stripped%:*}"
  port="${stripped##*:}"
  [[ "$port" == *[?]* ]] && port="${port%%[?]*}"

  sni=""; alpn=""; download_bandwidth=""; up=""; down=""
  for pair in ${query//&/ }; do
    case "$pair" in
      sni=*) sni="${pair#sni=}" ;;
      alpn=*) alpn="${pair#alpn=}" ;;
      download_bandwidth=*) download_bandwidth="${pair#download_bandwidth=}" ;;
      up=*) up="${pair#up=}" ;;
      down=*) down="${pair#down=}" ;;
    esac
  done

  printf "hysteria2\tserver=%s\tport=%s\tpassword=%s\tsni=%s\talpn=%s\tdownload_bandwidth=%s\tup=%s\tdown=%s\n" \
    "$server" "$port" "$password" "$sni" "$alpn" "$download_bandwidth" "$up" "$down"
}

## Brief: Parse vmess:// URI (base64-encoded JSON)
## Args: $1 - vmess URI
parse_vmess() {
  local uri=$1 b64 json
  b64="${uri#vmess://}"
  json=$(echo "$b64" | base64 -d 2>/dev/null) || {
    warn "Failed to decode vmess base64"
    return
  }

  local type uuid server port cipher sni alpn network tls fingerprint publicKey shortId spx
  local ws_path ws_headers_host ws_headers_key

  type=$(echo "$json" | jq -r '.type // "vmess"')
  uuid=$(echo "$json" | jq -r '.uuid // ""')
  server=$(echo "$json" | jq -r '.add // .address // .server // ""')
  port=$(echo "$json" | jq -r '.port // ""')
  cipher=$(echo "$json" | jq -r '.cipher // .aid // "auto"')
  sni=$(echo "$json" | jq -r '.sni // .host // ""')
  alpn=$(echo "$json" | jq -r '.alpn // ""')
  network=$(echo "$json" | jq -r '.net // .network // "tcp"')
  tls=$(echo "$json" | jq -r '.tls // ""')
  fingerprint=$(echo "$json" | jq -r '.fingerprint // .fp // ""')
  publicKey=$(echo "$json" | jq -r '.publicKey // .pbk // ""')
  shortId=$(echo "$json" | jq -r '.shortId // .sid // ""')
  spx=$(echo "$json" | jq -r '.spx // ""')
  ws_path=$(echo "$json" | jq -r '."ws-opts"?.path // .path // ""')
  ws_headers_host=$(echo "$json" | jq -r '."ws-opts"?.headers?.Host // .host // ""')
  ws_headers_key=$(echo "$json" | jq -r '."ws-opts"?.headers?.Key // ""')

  printf "vmess\ttype=%s\tuuid=%s\tserver=%s\tport=%s\tcipher=%s\tsni=%s\talpn=%s\tnetwork=%s\ttls=%s\tfingerprint=%s\tpublicKey=%s\tshortId=%s\tspx=%s\tws-path=%s\tws-headers-Host=%s\tws-headers-Key=%s\n" \
    "$type" "$uuid" "$server" "$port" "$cipher" "$sni" "$alpn" "$network" "$tls" "$fingerprint" "$publicKey" "$shortId" "$spx" "$ws_path" "$ws_headers_host" "$ws_headers_key"
}
