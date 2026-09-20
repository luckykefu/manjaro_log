# shadowsocks-rust 代理部署手册

## 服务器端部署

### 安装

```bash
sudo pacman -S --needed --noconfirm shadowsocks-rust
```

### 生成配置

```bash
readonly SS_PORT=8388
readonly SS_CFG=/etc/shadowsocks-rust/config.json
readonly SS_METHOD="2022-blake3-aes-256-gcm"

gen_config() {
    local pass
    pass=$(ssservice genkey -m "$SS_METHOD")
    sudo mkdir -p "$(dirname "$SS_CFG")"
    sudo tee "$SS_CFG" > /dev/null << EOF
{
    "server":      "0.0.0.0",
    "server_port": ${SS_PORT},
    "password":    "${pass}",
    "method":      "${SS_METHOD}",
    "mode":        "tcp_and_udp"
}
EOF
    echo "配置写入 $SS_CFG"
    cat "$SS_CFG"
}
```

### 启动服务

```bash
setup_service() {
    echo "配置 systemd 服务"
    # 幂等：先停掉所有旧实例
    sudo systemctl stop    'shadowsocks-rust-server@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust-server@*' 2>/dev/null || true
    sudo systemctl enable --now shadowsocks-rust-server@config.service
}
```

### 开放端口

```bash
readonly SS_PORT=8388
open_port() {
    local port="$1" proto="${2:-tcp}"
    echo "开放端口 ${port}/${proto}"
    if command -v firewall-cmd &>/dev/null; then
        sudo firewall-cmd --add-port="${port}/${proto}" --permanent 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
    elif command -v ufw &>/dev/null; then
        sudo ufw allow "${port}/${proto}" 2>/dev/null || true
    elif command -v iptables &>/dev/null; then
        sudo iptables -C INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null ||
            sudo iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
    else
        echo "未检测到防火墙工具，跳过"
    fi
}
open_port "$SS_PORT" tcp
open_port "$SS_PORT" udp
```

### 验证服务

```bash
verify() {
    echo "验证监听端口"
    ss -tlnp | grep ":${SS_PORT} " || echo "端口 $SS_PORT 未监听，请检查日志"
    echo "服务端就绪 ✓"
}
```

## 本地客户端配置(ss版)

### 安装

```bash
sudo pacman -S --needed --noconfirm shadowsocks-rust jq
```

### 拉取远程配置

```bash
readonly LOCAL_ADDR="0.0.0.0"
readonly LOCAL_PORT=1080
readonly SS_CFG=/etc/shadowsocks-rust/config.json

fetch_and_patch_config() {
    local remote_ip="$1"
    local tmpf
    tmpf=$(mktemp --suffix=.json)
    trap "rm -f '$tmpf'" EXIT

    scp "root@${remote_ip}:${SS_CFG}" "$tmpf"

    sudo mkdir -p "$(dirname "$SS_CFG")"
    jq --arg  server     "$remote_ip"   \
       --arg  local_addr "$LOCAL_ADDR"  \
       --argjson local_port "$LOCAL_PORT" \
       '.server = $server | .local_address = $local_addr | .local_port = $local_port' \
       "$tmpf" | sudo tee "$SS_CFG" > /dev/null
    echo "客户端配置写入 $SS_CFG"
}
fetch_and_patch_config "$ip"
```

### 启动服务

```bash
setup_service() {
    echo "重启 shadowsocks-rust 客户端"
    sudo systemctl stop    'shadowsocks-rust@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
    sudo pkill -x ssservice 2>/dev/null || true
    sudo systemctl enable --now shadowsocks-rust@config.service
}
```

### 开放端口

```bash
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
    else
        echo "未检测到防火墙工具，跳过"
    fi
}
```

### 验证

```bash
verify() {
    echo "验证"
    sudo systemctl status shadowsocks-rust@config.service --no-pager -l
    ss -tlnp | grep ":${LOCAL_PORT} " || echo "端口 $LOCAL_PORT 未监听"
    echo "客户端就绪 ✓"
}
```

## 本地客户端部署(clash版)

### 安装

### 拉取远程配置

### 配置转clash

```bash

readonly REMOTE_IP="${1:?用法: $0 <VPS-IP>}"
readonly SS_REMOTE_CFG="/etc/shadowsocks-rust/config.json"
readonly SS_LOCAL_TMP=$(mktemp --suffix=.json)
readonly DIR="$(cd "$(dirname "$0")" && pwd)"
readonly MIHOMO_DIR="$(cd "$DIR/../mihomo" && pwd)"
readonly TEMPLATE="$MIHOMO_DIR/config copy.yaml"
readonly OUTPUT="$MIHOMO_DIR/config.yaml"
readonly YQ="yq -yi"

trap "rm -f '$SS_LOCAL_TMP'" EXIT

sudo pacman -S --needed --noconfirm jq yq &>/dev/null

# 1. 从 VPS 拉取 SS 配置
echo "拉取 $REMOTE_IP:$SS_REMOTE_CFG ..."
scp "root@${REMOTE_IP}:${SS_REMOTE_CFG}" "$SS_LOCAL_TMP"

# 2. 修正 server 地址（VPS 配置里为 0.0.0.0）
jq --arg ip "$REMOTE_IP" '.server = $ip' "$SS_LOCAL_TMP" > "${SS_LOCAL_TMP}.fix"
mv "${SS_LOCAL_TMP}.fix" "$SS_LOCAL_TMP"

# 3. 解析 SS 配置
SERVER=$(jq -r '.server' "$SS_LOCAL_TMP")
PORT=$(jq -r '.server_port' "$SS_LOCAL_TMP")
METHOD=$(jq -r '.method' "$SS_LOCAL_TMP")
PASSWORD=$(jq -r '.password' "$SS_LOCAL_TMP")
NAME="ss-$SERVER"

echo "  节点: $SERVER:$PORT  $METHOD"

# 4. 基于模板生成纯净配置
[[ -f "$TEMPLATE" ]] || { echo "错误: 模板不存在 $TEMPLATE" >&2; exit 1; }

cp "$TEMPLATE" "$OUTPUT"

$YQ '.proxies = []' "$OUTPUT"
$YQ '.["proxy-groups"] = []' "$OUTPUT"
$YQ '.rules = []' "$OUTPUT"

$YQ '.proxies += [{"name": "'"$NAME"'", "type": "ss", "server": "'"$SERVER"'", "port": '"$PORT"', "cipher": "'"$METHOD"'", "password": "'"$PASSWORD"'", "udp": true}]' "$OUTPUT"

$YQ '.["proxy-groups"] += [{"name": "Proxy", "type": "select", "proxies": ["'"$NAME"'", "DIRECT"]}]' "$OUTPUT"
$YQ '.["proxy-groups"] += [{"name": "Auto", "type": "url-test", "proxies": ["'"$NAME"'"], "url": "https://www.gstatic.com/generate_204", "interval": 300}]' "$OUTPUT"

$YQ '.rules = ["DOMAIN-SUFFIX,local,DIRECT", "DOMAIN-SUFFIX,localhost,DIRECT", "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve", "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve", "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve", "GEOIP,CN,DIRECT", "MATCH,Proxy"]' "$OUTPUT"

echo "✓ 纯净配置已写入 $OUTPUT"
echo "运行: bash $MIHOMO_DIR/start.sh --tun"

```
