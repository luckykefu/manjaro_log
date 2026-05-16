write_config_yaml() {
  local out="$1" ns="$2"
  : "${ns:=223.5.5.5}"
  cat > "$out" <<YAML
mixed-port: 7897
allow-lan: true
mode: rule
log-level: info
external-controller: 127.0.0.1:9097

proxy-providers:
  my_sub:
    type: file
    path: ./providers/my_sub.yaml
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
    - '*.lan'
    - '*.local'
    - '*.arpa'
  default-nameserver:
    - $ns
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
    domain:
      - '+.google.com'
      - '+.facebook.com'
      - '+.youtube.com'
YAML
  yq eval . "$out" > /dev/null 2>&1 && sinfo "[yq] config yaml valid"
  sinfo "[config] wrote config: $out"
}
