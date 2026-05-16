PROVIDER_TMP=""
PROXY_COUNT=0

cleanup_parse() { rm -f "$PROVIDER_TMP"; }

download() {
  local url="$1" proxy="$2"
  local curl_opts=(-sL --compressed --connect-timeout 15 --max-time 30)
  [[ -n "$proxy" ]] && curl_opts+=(-x "$proxy") && sinfo "[subscribe] using proxy: $proxy"

  sinfo "[subscribe] downloading from: $url"
  local raw
  raw=$(curl "${curl_opts[@]}" "$url") || true
  [[ -z "$raw" ]] && raw=$(curl -sL --connect-timeout 15 --max-time 30 ${proxy:+-x "$proxy"} "$url" 2>/dev/null) || true
  [[ -z "$raw" ]] && serror "failed to fetch subscription: $url" && return 1
  sinfo "[subscribe] downloaded ${#raw} bytes"
  echo "$raw"
}

urldecode() {
  local str="$1" out="" c hex i=0
  while [[ $i -lt ${#str} ]]; do
    c="${str:$i:1}"
    case "$c" in
      '+') out+=' '; i=$((i+1)) ;;
      '%')
        hex="${str:$i+1:2}"
        if [[ "$hex" =~ [0-9a-fA-F]{2} ]]; then
          # shellcheck disable=SC2059
          printf -v c "\x${hex}"
          out+="$c"
          i=$((i+3))
        else
          out+='%'
          i=$((i+1))
        fi
        ;;
      *) out+="$c"; i=$((i+1)) ;;
    esac
  done
  echo "$out"
}

get_json_str() { local j="$1" k="$2"; jq -r ".${k} // empty" <<< "$j" 2>/dev/null || true; }
get_json_num() { local j="$1" k="$2"; jq -r ".${k} // empty" <<< "$j" 2>/dev/null || true; }
get_json_bool() { local j="$1" k="$2"; jq -r ".${k} // empty" <<< "$j" 2>/dev/null || true; }

yaml_str()   { local v="$2"; v="${v//\\/\\\\}"; echo "    $1: \"$v\"" >> "$PROVIDER_TMP"; }
yaml_bool()  { echo "    $1: $2"    >> "$PROVIDER_TMP"; }
yaml_int()   { echo "    $1: $2"    >> "$PROVIDER_TMP"; }
yaml_opt_str()  { [[ -n "$2" ]] && yaml_str "$1" "$2"; }
yaml_opt_bool() { [[ -n "$2" ]] && yaml_bool "$1" "$2"; }
yaml_header()   { echo "  - name: \"$1\"" >> "$PROVIDER_TMP"; }

parse_vless() {
  local uri="$1" frag="" query="" user host port
  [[ "$uri" == *"#"* ]] && frag="${uri##*#}" && uri="${uri%#*}"
  [[ "$uri" == *"?"* ]] && query="${uri##*\?}" && uri="${uri%%\?*}"
  user="${uri%%@*}"; local hp="${uri#*@}"
  [[ "$hp" == *":"* ]] && host="${hp%%:*}" && port="${hp#*:}" || host="$hp" && port="443"
  [[ ! "$port" =~ ^[0-9]+$ ]] && port=443

  local uuid; uuid=$(urldecode "$user")
  local name; name=$(urldecode "$frag") && [[ -z "$name" ]] && name="vless-${host}"

  local flow sni fp type security pbk sid encryption
  flow=$(get_qparam "$query" "flow") || true
  sni=$(get_qparam "$query" "sni") || true
  fp=$(get_qparam "$query" "fp") || true
  type=$(get_qparam "$query" "type") || true
  security=$(get_qparam "$query" "security") || true
  pbk=$(get_qparam "$query" "pbk") || true
  sid=$(get_qparam "$query" "sid") || true
  encryption=$(get_qparam "$query" "encryption") || true
  : "${sni:=$host}" "${fp:=chrome}" "${type:=tcp}" "${encryption:=none}"

  yaml_header "$name"
  yaml_str  type vless; yaml_str  server "$host"; yaml_int  port "$port"
  yaml_str  uuid "$uuid"; yaml_bool udp true; yaml_opt_str flow "$flow"
  yaml_bool tls true; yaml_str  servername "$sni"
  yaml_str  client-fingerprint "$fp"; yaml_str  network "$type"
  [[ "${security:-}" == "reality" && -n "${pbk:-}" ]] && { echo "    reality-opts:"; echo "      public-key: \"$pbk\""; echo "      short-id: \"${sid:-}\""; } >> "$PROVIDER_TMP"
  yaml_str encryption "$encryption"
  sinfo "[parser] parsed: $name (vless)"; PROXY_COUNT=$((PROXY_COUNT + 1))
}

parse_anytls() {
  local uri="$1" frag="" query="" user host port
  [[ "$uri" == *"#"* ]] && frag="${uri##*#}" && uri="${uri%#*}"
  [[ "$uri" == *"?"* ]] && query="${uri##*\?}" && uri="${uri%%\?*}"
  user="${uri%%@*}"; local hp="${uri#*@}"
  host="${hp%%:*}"; port="${hp#*:}"; [[ ! "$port" =~ ^[0-9]+$ ]] && port=443
  local password; password=$(urldecode "$user")
  local name; name=$(urldecode "$frag") && [[ -z "$name" ]] && name="anytls-${host}"
  local sni insecure
  sni=$(get_qparam "$query" "sni") || true; : "${sni:=$host}"
  insecure=$(get_qparam "$query" "insecure") || true
  yaml_header "$name"; yaml_str  type anytls; yaml_str  server "$host"
  yaml_int  port "$port"; yaml_str  password "$password"; yaml_bool udp true
  yaml_str  sni "$sni"; [[ "$insecure" == "1" ]] && yaml_bool skip-cert-verify true
  sinfo "[parser] parsed: $name (anytls)"; PROXY_COUNT=$((PROXY_COUNT + 1))
}

parse_tuic() {
  local uri="$1" frag="" query="" user host port
  [[ "$uri" == *"#"* ]] && frag="${uri##*#}" && uri="${uri%#*}"
  [[ "$uri" == *"?"* ]] && query="${uri##*\?}" && uri="${uri%%\?*}"
  user="${uri%%@*}"; local hp="${uri#*@}"
  host="${hp%%:*}"; port="${hp#*:}"; [[ ! "$port" =~ ^[0-9]+$ ]] && port=443
  local uuid; uuid=$(urldecode "$user")
  local name; name=$(urldecode "$frag") && [[ -z "$name" ]] && name="tuic-${host}"
  local password sni cc
  password=$(get_qparam "$query" "password") || true; : "${password:=$uuid}"
  sni=$(get_qparam "$query" "sni") || true; : "${sni:=$host}"
  cc=$(get_qparam "$query" "congestion_controller") || true; : "${cc:=bbr}"
  yaml_header "$name"; yaml_str  type tuic; yaml_str  server "$host"
  yaml_int  port "$port"; yaml_str  uuid "$uuid"; yaml_str  password "$password"
  yaml_bool udp true; yaml_str  sni "$sni"; yaml_bool skip-cert-verify true
  yaml_str  congestion-controller "$cc"
  sinfo "[parser] parsed: $name (tuic)"; PROXY_COUNT=$((PROXY_COUNT + 1))
}

parse_hysteria2() {
  local uri="$1" frag="" query="" user host port
  [[ "$uri" == *"#"* ]] && frag="${uri##*#}" && uri="${uri%#*}"
  [[ "$uri" == *"?"* ]] && query="${uri##*\?}" && uri="${uri%%\?*}"
  user="${uri%%@*}"; local hp="${uri#*@}"
  host="${hp%%:*}"; port="${hp#*:}"; [[ ! "$port" =~ ^[0-9]+$ ]] && port=443
  local password; password=$(urldecode "$user")
  local name; name=$(urldecode "$frag") && [[ -z "$name" ]] && name="hy2-${host}"
  local sni insecure up down
  sni=$(get_qparam "$query" "sni") || true; : "${sni:=$host}"
  insecure=$(get_qparam "$query" "insecure") || true
  up=$(get_qparam "$query" "up") || true; down=$(get_qparam "$query" "down") || true
  yaml_header "$name"; yaml_str  type hysteria2; yaml_str  server "$host"
  yaml_int  port "$port"; yaml_str  password "$password"; yaml_bool udp true
  yaml_str  sni "$sni"; [[ "$insecure" == "1" ]] && yaml_bool skip-cert-verify true
  yaml_opt_str up "$up"; yaml_opt_str down "$down"
  sinfo "[parser] parsed: $name (hysteria2)"; PROXY_COUNT=$((PROXY_COUNT + 1))
}

parse_ss() {
  local uri="$1" frag="" user host port
  [[ "$uri" == *"#"* ]] && frag="${uri##*#}" && uri="${uri%#*}"
  user="${uri%%@*}"; local hp="${uri#*@}"
  host="${hp%%:*}"; port="${hp#*:}"; [[ ! "$port" =~ ^[0-9]+$ ]] && port=443
  local name; name=$(urldecode "$frag") && [[ -z "$name" ]] && name="ss-${host}"
  local method password
  if echo "$user" | base64 -d &>/dev/null 2>&1; then
    local decoded; decoded=$(echo "$user" | base64 -d)
    method="${decoded%%:*}"; password="${decoded#*:}"
  else
    method="${user%%:*}"; password="${user#*:}"
  fi
  yaml_header "$name"; yaml_str  type ss; yaml_str  server "$host"
  yaml_int  port "$port"; yaml_str  cipher "$method"; yaml_str  password "$password"
  yaml_bool udp true
  sinfo "[parser] parsed: $name (ss)"; PROXY_COUNT=$((PROXY_COUNT + 1))
}

parse_vmess() {
  local b64="$1" frag=""
  [[ "$b64" == *"#"* ]] && frag="${b64##*#}" && b64="${b64%#*}"
  local std_b64; std_b64=$(echo "$b64" | tr '_-' '+/')
  local mod=$(( ${#std_b64} % 4 ))
  [[ $mod -eq 2 ]] && std_b64+="=="; [[ $mod -eq 3 ]] && std_b64+="="
  local json; json=$(echo "$std_b64" | base64 -d 2>/dev/null) || return 1
  local name; name=$(get_json_str "$json" "ps") || true
  [[ -z "$name" ]] && name=$(urldecode "$frag") || true
  [[ -z "$name" ]] && name="vmess"
  local add; add=$(get_json_str "$json" "add") || return 1
  local port; port=$(get_json_num "$json" "port") || true; : "${port:=443}"
  local id; id=$(get_json_str "$json" "id") || true
  local aid; aid=$(get_json_num "$json" "aid") || true; : "${aid:=0}"
  local scy; scy=$(get_json_str "$json" "scy") || true; : "${scy:=auto}"
  local net; net=$(get_json_str "$json" "net") || true
  local path; path=$(get_json_str "$json" "path") || true; : "${path:=/}"
  local host_h; host_h=$(get_json_str "$json" "host") || true; : "${host_h:=$add}"
  yaml_header "$name"; yaml_str  type vmess; yaml_str  server "$add"
  yaml_int  port "$port"; yaml_str  uuid "$id"; yaml_bool udp true
  yaml_int  alterId "$aid"; yaml_str  cipher "$scy"
  [[ "$net" == "ws" ]] && { yaml_str network "ws"; { echo "    ws-opts:"; echo "      path: \"$path\""; echo "      headers:"; echo "        Host: \"$host_h\""; } >> "$PROVIDER_TMP"; }
  sinfo "[parser] parsed: $name (vmess)"; PROXY_COUNT=$((PROXY_COUNT + 1))
}

get_qparam() {
  local query="$1" key="$2"
  [[ -z "$query" ]] && return 1
  local rest="${query#*"${key}="}"
  [[ "$rest" == "$query" ]] && return 1
  urldecode "${rest%%&*}"
}

decode() {
  local raw="$1"
  local cleaned line decoded text
  cleaned=$(echo "$raw" | tr -d '\r')
  text=""
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    decoded=$(echo "$line" | base64 -d 2>/dev/null) || continue
    text+="$decoded"$'\n'
  done <<< "$cleaned"
  if [[ -z "$text" ]]; then
    text=$(echo "$cleaned" | base64 -d 2>/dev/null) || text="$cleaned"
  fi
  if [[ -n "$text" ]]; then
    sinfo "[parser] decoded ${#raw} bytes of base64"
  else
    sinfo "[parser] not base64, using raw text"; text="$raw"
  fi
  echo "$text"
}

parse_proxies() {
  local text="$1"
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    case "$line" in
      vless://*)     parse_vless "${line#vless://}" ;;
      anytls://*)    parse_anytls "${line#anytls://}" ;;
      tuic://*)      parse_tuic "${line#tuic://}" ;;
      hysteria2://*) parse_hysteria2 "${line#hysteria2://}" ;;
      hy2://*)        parse_hysteria2 "${line#hy2://}" ;;
      ss://*)        parse_ss "${line#ss://}" ;;
      vmess://*)     parse_vmess "${line#vmess://}" || swarn "[parser] failed to parse: ${line:0:60}..." ;;
      *) swarn "[parser] unknown scheme, skipping: ${line:0:60}..." ;;
    esac
  done <<< "$text"
  sinfo "[parser] total proxies parsed: $PROXY_COUNT"
}

write_provider_yaml() {
  local out="$1"
  { echo "proxies:"; cat "$PROVIDER_TMP"; } > "$out"
  yq eval . "$out" > /dev/null 2>&1 && sinfo "[yq] provider yaml valid"
  sinfo "[config] wrote provider: $out ($PROXY_COUNT proxies)"
}

run_parse() {
  local subscribe_link="$1" output_dir="$2" nameserver="$3" proxy="$4"

  PROVIDER_TMP=$(mktemp)
  PROXY_COUNT=0
  trap cleanup_parse EXIT

  local raw; raw=$(download "$subscribe_link" "$proxy") || return 1
  local text; text=$(decode "$raw")
  parse_proxies "$text"

  [[ "$PROXY_COUNT" -eq 0 ]] && serror "no proxies found in subscription" && return 1

  mkdir -p "$output_dir/providers"
  write_provider_yaml "$output_dir/providers/my_sub.yaml"
  write_config_yaml "$output_dir/config.yaml" "$nameserver"
}
