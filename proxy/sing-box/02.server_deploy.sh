#!/usr/bin/env bash
# 远程 VPS 端：安装 sing-box，生成三协议服务端配置，下载 rule-set
set -euo pipefail

readonly CFG=/etc/sing-box/config.json

gen_cert() {
    local dir=/etc/sing-box
    sudo mkdir -p "$dir"
    [[ -f "$dir/cert.pem" ]] && return
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -days 3650 \
        -nodes -keyout "$dir/key.pem" -out "$dir/cert.pem" \
        -subj "/CN=sing-box" -addext "subjectAltName=DNS:sing-box"
    echo "自签证书已生成"
}

gen_config() {
    gen_cert
    echo "生成服务端配置（SS + Trojan + Hysteria2）"

    local ss_pass tj_pass hy2_pass
    ss_pass=$(sing-box generate rand 32 --base64)
    tj_pass=$(sing-box generate rand 16 --base64)
    hy2_pass=$(sing-box generate rand 16 --base64)

    sudo tee "$CFG" > /dev/null << EOF
{
  "log": { "level": "info" },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "::",
      "listen_port": 18388,
      "method": "2022-blake3-aes-256-gcm",
      "password": "$ss_pass"
    },
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "::",
      "listen_port": 8443,
      "users": [{ "name": "default", "password": "$tj_pass" }],
      "tls": {
        "enabled": true,
        "server_name": "sing-box",
        "certificate_path": "/etc/sing-box/cert.pem",
        "key_path": "/etc/sing-box/key.pem"
      }
    },
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": 8444,
      "up_mbps": 100,
      "down_mbps": 500,
      "users": [{ "name": "default", "password": "$hy2_pass" }],
      "tls": {
        "enabled": true,
        "server_name": "sing-box",
        "certificate_path": "/etc/sing-box/cert.pem",
        "key_path": "/etc/sing-box/key.pem"
      }
    }
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct" }
  ]
}
EOF
    echo "SS   密码: $ss_pass"
    echo "Trojan 密码: $tj_pass"
    echo "HY2  密码: $hy2_pass"
}

dl_ruleset() {
    local dir=/var/lib/sing-box/rule_set
    sudo mkdir -p "$dir"
    for rs in geosite-geolocation-cn geoip-cn; do
        local file="$dir/$rs.srs"
        [[ -f "$file" ]] && continue
        echo "下载 rule-set: $rs"
        case "$rs" in
            geosite*) url="https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/${rs}.srs" ;;
            geoip*)   url="https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/${rs}.srs" ;;
        esac
        sudo curl -fsSL "$url" -o "$file" && echo "  -> $(( $(wc -c < "$file") )) bytes"
    done
}

open_port() {
    local port="$1" proto="${2:-tcp}"
    if command -v firewall-cmd &>/dev/null; then
        sudo firewall-cmd --add-port="${port}/${proto}" --permanent 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
    elif command -v ufw &>/dev/null; then
        sudo ufw allow "${port}/${proto}" 2>/dev/null || true
    elif command -v iptables &>/dev/null; then
        sudo iptables -C INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null ||
            sudo iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
    fi
}

verify() {
    sleep 2
    sudo systemctl is-active sing-box >/dev/null && echo "sing-box 运行中 ✓" || echo "sing-box 未运行"
    for p in 18388 8443 8444; do
        ss -tlnp | grep -q ":$p " && echo "端口 $p 监听 ✓" || echo "端口 $p 未监听"
    done
}

if ! command -v sing-box &>/dev/null; then
    bash <(curl -fsSL https://sing-box.app/install.sh)
fi

gen_config
dl_ruleset
open_port 18388 tcp; open_port 18388 udp
open_port 8443  tcp
open_port 8444  tcp; open_port 8444 udp
verify
