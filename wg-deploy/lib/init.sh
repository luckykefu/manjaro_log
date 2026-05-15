#!/bin/bash
# lib/init.sh
# 服务端初始化: 检测防火墙、安装 wireguard-tools、开放端口、生成密钥、获取主网口名
#
# 入参:
#   WG_DIR - 配置目录 (默认 /etc/wireguard)
#   PORT   - WireGuard UDP 端口 (默认 51820)
#
# 输出 (stdout KEY=VALUE 格式):
#   FIREWALL=firewalld|ufw|nftables|iptables
#   SERVER_PRIV=<服务端私钥>
#   SERVER_PUB=<服务端公钥>
#   IFACE=<主网口名>
#
# 处理逻辑:
#   1 检测防火墙类型
#   2 安装 wireguard-tools
#   3 开放 UDP 端口
#   4 生成服务端密钥对
#   5 获取主网口名
#   返回 -> stdout 输出 KEY=VALUE

gen_init_script() {
    local wg_dir=${1:-/etc/wireguard}
    local port=${2:-51820}

    cat << SCRIPT
#!/bin/bash
set -e
WG_DIR="$wg_dir"
PORT=$port

FW=\$(command -v firewall-cmd &>/dev/null && echo firewalld || (command -v ufw &>/dev/null && echo ufw || (command -v nft &>/dev/null && echo nftables || echo iptables)))
echo "FIREWALL=\$FW"

sudo pacman -S --noconfirm --needed wireguard-tools

case \$FW in
    firewalld) sudo firewall-cmd --add-port=\$PORT/udp --permanent && sudo firewall-cmd --reload ;;
    ufw) sudo ufw allow \$PORT/udp ;;
    nftables) echo "WARN=nftables_open_port_manually" ;;
    *) sudo iptables -A INPUT -p udp --dport \$PORT -j ACCEPT ; echo "WARN=iptables_not_persistent" ;;
esac

sudo mkdir -p "\$WG_DIR"
WG_PRIV=\$(sudo wg genkey)
WG_PUB=\$(echo "\$WG_PRIV" | sudo wg pubkey)
echo "\$WG_PRIV" | sudo tee "\$WG_DIR/privatekey" > /dev/null
echo "\$WG_PUB" | sudo tee "\$WG_DIR/publickey" > /dev/null
sudo chmod 600 "\$WG_DIR/privatekey"
echo "SERVER_PRIV=\$WG_PRIV"
echo "SERVER_PUB=\$WG_PUB"

IFACE=\$(ip route get 1.1.1.1 | awk '{print \$5; exit}')
echo "IFACE=\$IFACE"
SCRIPT
}

run_init() {
    local ip=$1 port=$2 wg_dir=$3
    local script local_file remote_file

    sdebug "run_init ip=$ip port=$port wg_dir=$wg_dir"

    script=$(gen_init_script "$wg_dir" "$port")
    local_file="/tmp/wg_init_$$.sh"
    remote_file="/tmp/wg_init.sh"

    echo "$script" > "$local_file"
    scp "$local_file" "root@${ip}:${remote_file}" || {
        rm -f "$local_file"
        serror "scp init script failed"
        return 1
    }

    local output
    output=$(ssh "root@${ip}" "bash $remote_file") || {
        rm -f "$local_file"
        serror "ssh exec init script failed"
        return 1
    }
    rm -f "$local_file"

    local firewall="" server_priv="" server_pub="" iface=""
    local line key val
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_]+)=(.+)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            case "$key" in
                FIREWALL)     firewall=$val ;;
                SERVER_PRIV)  server_priv=$val ;;
                SERVER_PUB)   server_pub=$val ;;
                IFACE)        iface=$val ;;
            esac
        fi
    done <<< "$output"

    if [[ -z "$server_priv" || -z "$server_pub" ]]; then
        serror "server init failed: missing keys in output"
        sdebug "output:\n$output"
        return 1
    fi

    sinfo "server firewall: $firewall"
    sdebug "server iface=$iface"

    echo "FIREWALL=$firewall"
    echo "SERVER_PRIV=$server_priv"
    echo "SERVER_PUB=$server_pub"
    echo "IFACE=$iface"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run_init "$@"
fi
