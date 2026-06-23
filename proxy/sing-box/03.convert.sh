#!/bin/bash
# 服务端配置 → 单协议/多协议客户端配置
# Usage:
#   $0 [-t] <server_ip> [protocol] [input_file] [output_path]
#     -t           TUN 模式（默认: mixed 本地代理 :1080）
#     server_ip    服务器 IP
#     protocol     协议: ss|trojan|hy2|all （默认 all）
#     input_file   本地服务端配置文件（可选，不传则 SCP 拉取）
#     output_path  输出路径（默认 /etc/sing-box/client.json, - 输出到 stdout）
set -euo pipefail

MODE="mixed"
PROTO="all"
SERVER_IP=""
LOCAL_INPUT=""
OUTFILE=""

usage() {
    echo "Usage: $0 [-t] <server_ip> [protocol] [input_file] [output_path]"
    echo "  -t               TUN 全局 VPN（默认: mixed :1080 代理）"
    echo "  server_ip        服务器 IP"
    echo "  protocol         ss|trojan|hy2|all（默认 all）"
    echo "  input_file       本地服务端配置（可选，默认从服务器 SCP 拉取）"
    echo "  output_path      - 输出到 stdout（默认 /etc/sing-box/client.json）"
    exit 0
}

while getopts "th" opt; do
    case "$opt" in
        t) MODE="tun" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

SERVER_IP="${1:-}"
PROTO="${2:-all}"
LOCAL_INPUT="${3:-}"
OUTFILE="${4:-/etc/sing-box/client.json}"

[[ -z "$SERVER_IP" ]] && usage
case "$PROTO" in ss|trojan|hy2|all) ;; *) usage ;; esac

JQ_TEMPLATE='
def to_outbound:
  if .type == "shadowsocks" then
    { type: "shadowsocks", tag: "ss-out",
      server: $ip, server_port: .listen_port,
      method: (.method // "2022-blake3-aes-256-gcm"),
      password: .password }
  elif .type == "trojan" then
    { type: "trojan", tag: "trojan-out",
      server: $ip, server_port: .listen_port,
      password: .users[0].password,
      tls: { enabled: true, insecure: true,
             server_name: (.tls.server_name // "") } }
  elif .type == "hysteria2" then
    { type: "hysteria2", tag: "hy2-out",
      server: $ip, server_port: .listen_port,
      password: .users[0].password,
      up_mbps: (.up_mbps // 100), down_mbps: (.down_mbps // 500),
      tls: { enabled: true, insecure: true,
             server_name: (.tls.server_name // "") } }
  else empty end;

def selector_outbounds:
  [$inbounds[] | to_outbound | select(. != null) | .tag];

def tun_config:
  { type: "tun", tag: "tun-in",
    address: ["172.19.0.1/30"], mtu: 9000,
    auto_route: true, auto_redirect: true, strict_route: true,
    route_exclude_address: ["192.168.0.0/16","10.0.0.0/8","172.16.0.0/12"] };

def mixed_config:
  { type: "mixed", tag: "mixed-in",
    listen: "127.0.0.1", listen_port: 1080 };

{
  log: { level: "warn" },
  dns: {
    servers: ([
      { tag: "dns-remote", type: "tls", server: "8.8.8.8" },
      { tag: "dns-local",  type: "udp", server: "223.5.5.5" }
    ] + if $mode == "tun" then [{ tag: "dns-fakeip", type: "fakeip", inet4_range: "198.18.0.0/15" }] else [] end),
    rules: ([
      { rule_set: "geosite-geolocation-cn", server: "dns-local" }
    ] + if $mode == "tun" then [{ query_type: ["A","AAAA"], server: "dns-fakeip" }] else [] end),
    final: "dns-remote",
    strategy: "prefer_ipv4"
  },
  inbounds: [if $mode == "tun" then tun_config else mixed_config end],
  outbounds: ([
    { type: "direct", tag: "direct" }
  ] + [$inbounds[] | to_outbound] + (
    if ($mode == "tun" or ($proto == "all")) then [
      { type: "selector", tag: "auto",
        outbounds: selector_outbounds, default: (selector_outbounds[0] // "direct") },
      { type: "urltest", tag: "best",
        outbounds: selector_outbounds,
        url: "https://www.gstatic.com/generate_204", interval: "5m", tolerance: 50 }
    ] else [] end
  )),
  route: {
    rules: ([
      { ip_is_private: true, outbound: "direct" },
      { rule_set: "geosite-geolocation-cn", outbound: "direct" }
    ] + if $mode == "tun" then [
      { action: "sniff" },
      { protocol: "dns", action: "hijack-dns" }
    ] else [] end),
    rule_set: [{
      tag: "geosite-geolocation-cn",
      type: "local",
      format: "binary",
      path: (if $rules_dir != "" then $rules_dir else "/etc/sing-box/rule-set" end) + "/geosite-geolocation-cn.srs"
    }],
    final: (if $proto != "all" then (selector_outbounds[0] // "direct") else "auto" end),
    auto_detect_interface: ($mode == "tun"),
    default_domain_resolver: "dns-local"
  }
} + if $mode == "tun" then {
  experimental: {
    cache_file: { enabled: true, store_fakeip: true, store_rdrc: true }
  }
} else {} end
'

generate() {
    local mode="$1" proto="$2" ip="$3" input="$4" outfile="$5"
    local tmpf

    if [[ -n "$input" && -f "$input" ]]; then
        tmpf="$input"
    else
        tmpf=$(mktemp --suffix=.json)
        trap "rm -f '$tmpf'" EXIT
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            "root@${ip}:/etc/sing-box/config.json" "$tmpf"
    fi

    if [[ "$outfile" == "-" ]]; then
        local_rules_dir=""
    else
        outdir="$(cd "$(dirname "$outfile")" && pwd)"
        local_rules_dir="$outdir/rule-set"
        sudo mkdir -p "$outdir"
        sudo chown "$(id -u):$(id -g)" "$outdir"
    fi

    if [[ -n "$local_rules_dir" ]]; then
        sudo mkdir -p "$local_rules_dir"
        sudo chown "$(id -u):$(id -g)" "$local_rules_dir"
        for rs in geosite-geolocation-cn; do
            local_rs="$local_rules_dir/$rs.srs"
            [[ -f "$local_rs" ]] && continue
            echo "拷贝 rule-set: $rs"
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                "root@${ip}:/var/lib/sing-box/rule_set/$rs.srs" "$local_rs" && \
                echo "  -> $(( $(wc -c < "$local_rs") )) bytes"
        done
    fi

    # 根据 proto 过滤 inbounds
    local filtered
    if [[ "$proto" == "all" ]]; then
        filtered=$(cat "$tmpf")
    else
        filtered=$(jq --arg proto "$proto" '
            .inbounds |= map(select(
                ($proto == "ss"     and .type == "shadowsocks") or
                ($proto == "trojan" and .type == "trojan")      or
                ($proto == "hy2"    and .type == "hysteria2")
            ))
        ' "$tmpf")
    fi

    local json
    inbounds_json=$(echo "$filtered" | jq '.inbounds')
    json=$(jq -n \
        --arg mode "$mode" \
        --arg proto "$proto" \
        --arg ip "$ip" \
        --arg rules_dir "$local_rules_dir" \
        --argjson inbounds "$inbounds_json" \
        "$JQ_TEMPLATE" \
        --indent 2)

    if [[ "$outfile" == "-" ]]; then
        echo "$json"
    else
        echo "$json" | sudo tee "$outfile" > /dev/null
        echo "客户端配置写入 $outfile"
    fi
}

generate "$MODE" "$PROTO" "$SERVER_IP" "$LOCAL_INPUT" "$OUTFILE"
