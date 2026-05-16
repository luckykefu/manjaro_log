#! /usr/bin/env bash
# main.sh — mihomo 一站式配置
# ========================================================
# 入参说明
# | 选项             | 默认值             | 说明        |
# |------------------|--------------------|-------------|
# | --subscribe URL  | (必填)             | 订阅链接     |
# | --output DIR     | ~/.config/mihomo   | 配置输出目录 |
# | --nameserver IP  | 223.5.5.5          | DNS          |
# |                  |                    |             |
# | 返回 0           | 成功               |             |
# | 返回 1           | 失败               |             |
# ========================================================
# 处理逻辑:
#
# sudo pacman -S mihomo
#   ↓
# 写入 config.yaml (proxy-providers type: http)
#   ↓
# nohup mihomo -d (mihomo 自动拉取订阅)
#   ↓
# curl gstatic → 检测连通性

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

main() {
    local url="" dir="$HOME/.config/mihomo" ns="223.5.5.5"

    while [[ $# -gt 0 ]]; do case "$1" in
        --subscribe|-s) url="$2"; shift 2 ;; --output|-o) dir="$2"; shift 2 ;;
        --nameserver) ns="$2"; shift 2 ;;
        --help|-h) sed -n "4,9p" "$0"; exit 0 ;; *) echo "unknown: $1"; exit 1 ;;
    esac; done

    [[ -z "$url" ]] && { sed -n "4,9p" "$0"; exit 1; }

    sudo pacman -S --needed --noconfirm archlinuxcn/mihomo

    mkdir -p "$dir"
    cat > "$dir/config.yaml" <<CONF
mixed-port: 7897
allow-lan: true
mode: rule
log-level: info
external-controller: 127.0.0.1:9097

proxy-providers:
  my_sub:
    type: http
    url: ${url}
    interval: 86400
    health-check:
      enable: true
      interval: 300
      url: http://www.gstatic.com/generate_204

proxy-groups:
  - name: proxy
    type: select
    use:
      - my_sub
    proxies:
      - auto
      - DIRECT
  - name: auto
    type: url-test
    use:
      - my_sub
    url: http://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50

rules:
  - DOMAIN-KEYWORD,google,proxy
  - DOMAIN-KEYWORD,youtube,proxy
  - DOMAIN-KEYWORD,github,proxy
  - DOMAIN-KEYWORD,openai,proxy
  - DOMAIN-KEYWORD,telegram,proxy
  - DOMAIN-KEYWORD,twitter,proxy
  - DOMAIN-SUFFIX,cn,DIRECT
  - DOMAIN-KEYWORD,-cn,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,proxy

dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - "*.lan"
    - "*.local"
    - "*.arpa"
  default-nameserver:
    - ${ns}
  nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
  fallback:
    - tls://8.8.4.4
    - tls://1.1.1.1
  proxy-server-nameserver:
    - https://doh.pub/dns-query
  fallback-filter:
    geoip: true
    geoip-code: CN
CONF

    nohup mihomo -d "$dir" > /tmp/mihomo.log 2>&1 & disown
    for _ in 1 2 3 4 5; do ss -tlnp 2>/dev/null | grep -q :7897 && break; sleep 1; done

    sleep 2
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -x "http://127.0.0.1:7897" "http://www.gstatic.com/generate_204") || true
    [[ "$code" != "204" ]] && return 1
}

main "$@"
