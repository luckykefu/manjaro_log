#!/bin/bash
# lib/apply.sh
# 服务端配置应用: 启用 IP 转发、清理旧接口、写入服务端 .conf、启动 wg-quick
#
# 入参 (环境变量):
#   WG_DIR         - 配置目录
#   WG_NAME        - 接口名 (通常是 IP 去点)
#   IFACE          - 主网口名
#   LOCAL_PUB      - 客户端公钥
#   SERVER_PRIV    - 服务端私钥
#   TUNNEL_SERVER  - 隧道服务端 IP
#   TUNNEL_CLIENT  - 隧道客户端 IP
#   SUBNET         - 子网掩码位数
#   PORT           - WireGuard UDP 端口
#
# 处理逻辑:
#   1 启用 net.ipv4.ip_forward
#   2 清理旧 wg 接口
#   3 写入服务端 .conf (内嵌 iptables PostUp/PostDown)
#   4 chmod 600
#   5 systemctl enable + restart wg-quick
#   返回 -> 成功/失败

gen_apply_script() {
    local wg_dir=$1 wg_name=$2 iface=$3 local_pub=$4
    local server_priv=$5 tunnel_client=$6 tunnel_server=$7
    local subnet=$8 port=$9

    cat << SCRIPT
#!/bin/bash
set -e
CUR=\$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 0)
if [[ "\$CUR" != "1" ]]; then
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl -p > /dev/null 2>&1
fi

sudo iptables -D INPUT -i "$wg_name" -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i "$wg_name" -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -o "$iface" -j MASQUERADE 2>/dev/null || true
sudo wg show interfaces 2>/dev/null | xargs -r -I{} sudo wg-quick down {} 2>/dev/null || true
sudo wg show interfaces 2>/dev/null | xargs -r -I{} sudo ip link delete dev {} 2>/dev/null || true

SVR_CFG="$wg_dir/$wg_name.conf"
sudo tee "\$SVR_CFG" > /dev/null << WGEOF
[Interface]
Address = $tunnel_server/$subnet
ListenPort = $port
PrivateKey = $server_priv
PostUp = iptables -D INPUT -i $wg_name -j ACCEPT 2>/dev/null || true; iptables -I INPUT 1 -i $wg_name -j ACCEPT || true; iptables -A FORWARD -i $wg_name -j ACCEPT || true; iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE || true
PostDown = iptables -D INPUT -i $wg_name -j ACCEPT 2>/dev/null || true; iptables -D FORWARD -i $wg_name -j ACCEPT || true; iptables -t nat -D POSTROUTING -o $iface -j MASQUERADE || true

[Peer]
PublicKey = $local_pub
AllowedIPs = $tunnel_client/32
WGEOF

sudo chmod 600 "\$SVR_CFG"
sudo systemctl enable "wg-quick@$wg_name" && sudo systemctl restart "wg-quick@$wg_name"
sudo iptables -D INPUT -i "$wg_name" -j ACCEPT 2>/dev/null || true; sudo iptables -I INPUT 1 -i "$wg_name" -j ACCEPT || true
sudo wg show
SCRIPT
}

run_apply() {
    local ip=$1 wg_dir=$2 wg_name=$3 iface=$4 local_pub=$5
    local server_priv=$6 cfg_ip=$7 cfg_port=$8 tunnel_client=$9
    local tunnel_server=${10} subnet=${11}
    local script local_file remote_file debug_out dmesg_out

    sdebug "run_apply ip=$ip wg_name=$wg_name"

    script=$(gen_apply_script \
        "$wg_dir" "$wg_name" "$iface" "$local_pub" \
        "$server_priv" "$tunnel_client" "$tunnel_server" \
        "$subnet" "$cfg_port")

    local_file="/tmp/wg_apply_$$.sh"
    remote_file="/tmp/wg_apply.sh"

    echo "$script" > "$local_file"
    scp "$local_file" "root@${ip}:${remote_file}" || {
        rm -f "$local_file"
        serror "scp apply script failed"
        return 1
    }

    ssh "root@${ip}" "bash $remote_file" || {
        debug_out=$(ssh "root@${ip}" \
            "sudo systemctl status wg-quick@${wg_name} 2>&1 || true; echo '---'; sudo journalctl -xeu wg-quick@${wg_name} --no-pager 2>&1 | tail -20 || true" 2>/dev/null || echo "")
        dmesg_out=$(ssh "root@${ip}" \
            "sudo dmesg | grep -i wireguard | tail -5 2>/dev/null || true" 2>/dev/null || echo "")
        serror "wg-quick@${wg_name} failed"
        serror "--- debug ---\n${debug_out}--- dmesg ---\n${dmesg_out}"
        rm -f "$local_file"
        return 1
    }

    rm -f "$local_file"
    sdebug "wg-quick@${wg_name} started"
    sinfo "server wg-quick@${wg_name} enabled and restarted"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run_apply "$@"
fi
