#!/bin/bash
set -euo pipefail

MODE="mixed"

usage() {
  echo "Usage: $0 [-t] <server_ip> [input_file] [output_path]"
  echo "  -t          - TUN 全局 VPN 模式（默认: mixed 本地代理 :1080）"
  echo "  server_ip   - 服务器 IP（必填，用于配置中的 server 字段）"
  echo "  input_file  - 本地服务端配置文件（可选，不传则 SCP 从服务器拉取）"
  echo "  output_path - 客户端配置文件输出路径（默认: /etc/sing-box/client.json, - 输出到 stdout）"
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

if [ $# -lt 1 ]; then
  usage
fi

SERVER_IP="$1"
LOCAL_INPUT="${2:-}"
OUTFILE="${3:-/etc/sing-box/client.json}"

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
  elif .type == "vmess" then
    { type: "vmess", tag: "vmess-out",
      server: $ip, server_port: .listen_port,
      uuid: .users[0].uuid,
      security: "auto" }
  elif .type == "vless" then
    { type: "vless", tag: "vless-out",
      server: $ip, server_port: .listen_port,
      uuid: .users[0].uuid,
      flow: "xtls-rprx-vision" }
  else
    { type: "direct", tag: (.tag + "-unhandled") }
  end;

def to_selector_entry:
  if .type == "shadowsocks" then "ss-out"
  elif .type == "trojan" then "trojan-out"
  elif .type == "hysteria2" then "hy2-out"
  elif .type == "vmess" then "vmess-out"
  elif .type == "vless" then "vless-out"
  else empty end;

def tun_config:
  {
    type: "tun",
    tag: "tun-in",
    address: ["172.19.0.1/30"],
    mtu: 9000,
    auto_route: true,
    auto_redirect: true,
    strict_route: true,
    route_exclude_address: [
      "192.168.0.0/16",
      "10.0.0.0/8",
      "172.16.0.0/12"
    ]
  };

def mixed_config:
  {
    type: "mixed",
    tag: "mixed-in",
    listen: "127.0.0.1",
    listen_port: 1080
  };

{
  log: { level: "warn" },
  dns: {
    servers: ([
      { tag: "dns-remote", type: "tls", server: "8.8.8.8" },
      { tag: "dns-local",  type: "udp", server: "223.5.5.5" }
    ] + if $mode == "tun" then [{ tag: "dns-fakeip", type: "fakeip", inet4_range: "198.18.0.0/15" }] else [] end),
    rules: ([
      { rule_set: "geosite-geolocation-cn", server: "dns-local" }
    ] + if $mode == "tun" then [{ query_type: ["A", "AAAA"], server: "dns-fakeip" }] else [] end),
    final: "dns-remote",
    strategy: "prefer_ipv4"
  },
  inbounds: [if $mode == "tun" then tun_config else mixed_config end],
  outbounds: ([
    { type: "direct", tag: "direct" }
  ] + [$cfg.inbounds[] | to_outbound] + [
    {
      type: "selector",
      tag: "auto",
      outbounds: [$cfg.inbounds[] | to_selector_entry | select(. != null)],
      default: "ss-out"
    },
    {
      type: "urltest",
      tag: "best",
      outbounds: [$cfg.inbounds[] | to_selector_entry | select(. != null)],
      url: "https://www.gstatic.com/generate_204",
      interval: "5m",
      tolerance: 50
    }
  ]),
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
    final: "auto",
    auto_detect_interface: ($mode == "tun"),
    default_domain_resolver: "dns-local"
  }
} +
if $mode == "tun" then {
  experimental: {
    cache_file: {
      enabled: true,
      store_fakeip: true,
      store_rdrc: true
    }
  }
} else {} end
'

fetch_and_patch() {
    local mode="$1" ip="$2" input="$3" outfile="$4"
    local tmpf

    if [ -n "$input" ] && [ -f "$input" ]; then
        tmpf="$input"
    else
        tmpf=$(mktemp --suffix=.json)
        trap "rm -f '$tmpf'" EXIT
        SCP_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        scp $SCP_OPTS "root@${ip}:/etc/sing-box/config.json" "$tmpf"
    fi

    if [ "$outfile" = "-" ]; then
        local_rules_dir=""
    else
        outdir="$(cd "$(dirname "$outfile")" && pwd)"
        local_rules_dir="$outdir/rule-set"
        sudo mkdir -p "$outdir" "$local_rules_dir"
    fi

    # 本地 rule-set（stdout 模式跳过）
    if [[ -n "$local_rules_dir" ]]; then
        SCP_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        for rs in geosite-geolocation-cn; do
            local_rs="$local_rules_dir/$rs.srs"
            [[ -f "$local_rs" ]] && continue
            echo "拷贝 rule-set: $rs"
            if scp $SCP_OPTS "root@${ip}:/var/lib/sing-box/rule_set/$rs.srs" "$local_rs" 2>/dev/null; then
                echo "  -> 从服务器拉取，$(( $(wc -c < "$local_rs") )) bytes"
            else
                echo "  -> 拷贝失败！请确认服务器 $ip 上存在 /var/lib/sing-box/rule_set/$rs.srs" >&2
                exit 1
            fi
        done
    fi

    local json
    json=$(jq -n --arg mode "$mode" --arg ip "$ip" --arg rules_dir "$local_rules_dir" --argjson cfg "$(cat "$tmpf")" "$JQ_TEMPLATE" --indent 2)

    if [ "$outfile" = "-" ]; then
        echo "$json"
    else
        echo "$json" | sudo tee "$outfile" > /dev/null
        echo "客户端配置写入 $outfile"
    fi
}

fetch_and_patch "$MODE" "$SERVER_IP" "$LOCAL_INPUT" "$OUTFILE"
