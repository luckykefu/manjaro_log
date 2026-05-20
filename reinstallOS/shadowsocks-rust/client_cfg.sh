#!/usr/bin/env bash
remote_ip="${1:-202.182.112.91}"
local_port="1080"
local_addr="0.0.0.0"

install_ss() {
    sudo pacman -S --needed --noconfirm shadowsocks-rust
}

get_remote_cfg() {
    tmpf=$(mktemp)
    trap 'rm -f "$tmpf"' EXIT
    echo "==> 从 ${remote_ip} 拉取服务端配置..."
    scp "root@${remote_ip}:/etc/shadowsocks-rust/config.json" "$tmpf"
}

gen_client_cfg() {
    echo "==> 生成客户端配置..."
    sudo mkdir -p /etc/shadowsocks-rust
    jq --arg server "$remote_ip" \
       --arg local_addr "$local_addr" \
       --argjson local_port "$local_port" \
       '.server = $server | . + {local_address: $local_addr, local_port: $local_port}' \
       "$tmpf" | sudo tee /etc/shadowsocks-rust/config.json > /dev/null
}

stop_old_instances() {
    echo "==> 停掉已有客户端实例..."
    sudo systemctl stop    'shadowsocks-rust@*' 2>/dev/null || true
    sudo systemctl disable 'shadowsocks-rust@*' 2>/dev/null || true
    sudo pkill -x ssservice 2>/dev/null || true
}

start_ss() {
    echo "==> 启动 shadowsocks-rust 客户端..."
    sudo systemctl enable --now shadowsocks-rust@config.service
}

port_open() {
    local port="$local_port"
    local proto=tcp

    if command -v firewall-cmd &>/dev/null; then
        echo "==> firewalld detected"
        sudo firewall-cmd --add-port="${port}/${proto}" --permanent 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
    elif command -v ufw &>/dev/null; then
        echo "==> ufw detected"
        sudo ufw allow "${port}/${proto}" 2>/dev/null || true
    elif command -v iptables &>/dev/null; then
        echo "==> iptables detected"
        sudo iptables -C INPUT -p "${proto}" --dport "${port}" -j ACCEPT 2>/dev/null ||
            sudo iptables -A INPUT -p "${proto}" --dport "${port}" -j ACCEPT
    else
        echo "==> 未检测到防火墙工具，跳过"
    fi
}

verify() {
    echo "==> 验证..."
    sudo systemctl status shadowsocks-rust@config.service --no-pager -l
    sudo ss -tlnp | grep ":${local_port} "
}

install_ss
get_remote_cfg
gen_client_cfg
stop_old_instances
port_open
start_ss
verify
