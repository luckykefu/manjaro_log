#!/bin/bash
# wg-deploy.sh
# WireGuard 一键部署工具 (Shell 版)
#
# 自动化部署 WireGuard 服务端与客户端，支持 Manjaro/Arch Linux 环境
# 通过 SCP 推送 bash 脚本到远程服务端执行，替代逐条 SSH 命令
#
# 入参:
#   --server-ip      服务端公网 IP (默认 64.176.225.208)
#   --port           WireGuard UDP 端口 (默认 51820)
#   --dir            配置目录 (默认 /etc/wireguard)
#   --tunnel-srv     隧道服务端 IP (默认 10.0.0.1)
#   --tunnel-cli     隧道客户端 IP (默认 10.0.0.2)
#   --subnet         子网掩码位数 (默认 24)
#   --switch IP      用已有配置快速连接
#
# 环境变量:
#   WG_SERVER_IP     WG_PORT   WG_DIR
#   WG_TUNNEL_SERVER WG_TUNNEL_CLIENT  WG_SUBNET
#
# 处理逻辑:
#
# --switch 模式:
#   |- 解析 --switch IP
#   +- 调用 switch_wireguard()
#
# 部署模式:
#   1 -> push_key             SSH 公钥推送至服务端
#   2 -> ensure_tools         本地检查 wireguard-tools
#   3 -> run_init             服务端初始化 (防火墙/安装/密钥/网口)
#   4 -> gen_keys             本地生成密钥对
#   5 -> write_config         写入客户端 .conf
#   6 -> run_apply            服务端配置脚本 (转发/配置/启动)
#   7 -> save_server_pubkey   保存服务端公钥
#   8 -> start_wg             启动本地 wg-quick
#   9 -> ping 测试            验证隧道连通性
#  10 -> key_exchange         双向 SSH 密钥交换
#   返回 -> 部署成功/失败

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/client.sh"
source "${SCRIPT_DIR}/lib/init.sh"
source "${SCRIPT_DIR}/lib/apply.sh"

DEFAULT_WG_IP="64.176.225.208"
DEFAULT_WG_PORT=51820
DEFAULT_WG_DIR="/etc/wireguard"
DEFAULT_WG_SERVER_IP="10.0.0.1"
DEFAULT_WG_CLIENT_IP="10.0.0.2"
DEFAULT_WG_SUBNET="24"

parse_arg_or_env() {
    local key=$1 default=$2
    local env_key
    env_key="WG_$(echo "$key" | tr '-' '_' | tr '[:lower:]' '[:upper:]')"
    echo "${!env_key:-$default}"
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --server-ip IP     Server public IP (default: $DEFAULT_WG_IP)
  --port PORT        WireGuard UDP port (default: $DEFAULT_WG_PORT)
  --dir DIR          Config directory (default: $DEFAULT_WG_DIR)
  --tunnel-srv IP    Tunnel server IP (default: $DEFAULT_WG_SERVER_IP)
  --tunnel-cli IP    Tunnel client IP (default: $DEFAULT_WG_CLIENT_IP)
  --subnet N         Subnet mask bits (default: $DEFAULT_WG_SUBNET)
  --switch IP        Quick connect with existing config

Environment variables:
  WG_SERVER_IP, WG_PORT, WG_DIR, WG_TUNNEL_SERVER, WG_TUNNEL_CLIENT, WG_SUBNET
EOF
    exit 0
}

switch_wireguard() {
    local ip=$1
    local wg_name
    wg_name=$(echo "$ip" | tr '.' '-')
    sdebug "switch_wireguard ip=$ip wg_name=$wg_name"

    step 1 2 "Clean old interfaces"
    switch_wg "$wg_name" "$DEFAULT_WG_DIR" || return 1

    step 2 2 "Ping test"
    if ping -c 3 -W 3 "$DEFAULT_WG_SERVER_IP" &>/dev/null; then
        ok "Ping OK!"
    else
        local status
        status=$(sudo wg show 2>/dev/null || echo "wg show failed")
        serror "ping failed"
        serror "--- wg status ---\n${status}"
        return 1
    fi
    ok "WireGuard ${wg_name} connected"
}

deploy_wireguard() {
    local ip=$1 port=$2 wg_dir=$3
    local tunnel_server=$4 tunnel_client=$5 subnet=$6
    local wg_name
    wg_name=$(echo "$ip" | tr '.' '-')
    local total=10

    sdebug "deploy_wireguard ip=$ip port=$port wg_name=$wg_name"

    # ----  1 ----
    step 1 $total "Push SSH public key"
    push_key "$ip" || return 1

    # ----  2 ----
    step 2 $total "Check client dependencies"
    ensure_tools || return 1

    # ----  3 ----
    step 3 $total "Server init script (firewall + install + keys + iface)"
    local init_output
    init_output=$(run_init "$ip" "$port" "$wg_dir") || return 1

    local firewall server_priv server_pub iface
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"
            case "$key" in
                FIREWALL)    firewall=$val ;;
                SERVER_PRIV) server_priv=$val ;;
                SERVER_PUB)  server_pub=$val ;;
                IFACE)       iface=$val ;;
            esac
        fi
    done <<< "$init_output"

    # ----  4 ----
    step 4 $total "Generate client key pair"
    local local_pub
    local_pub=$(gen_keys "$wg_dir") || return 1

    # ----  5 ----
    step 5 $total "Write client config"
    write_config "$wg_dir" "$wg_name" "$server_pub" \
        "$tunnel_client" "$subnet" "$tunnel_server" "$ip" "$port" || return 1

    # ----  6 ----
    step 6 $total "Server apply script (config + forwarding + start)"
    run_apply "$ip" "$wg_dir" "$wg_name" "$iface" "$local_pub" \
        "$server_priv" "$ip" "$port" "$tunnel_client" "$tunnel_server" "$subnet" || return 1

    # ----  7 ----
    step 7 $total "Save server public key locally"
    save_server_pubkey "$wg_dir" "$server_pub" || return 1

    # ----  8 ----
    step 8 $total "Start wg-quick locally"
    start_wg "$wg_name" || return 1

    # ----  9 ----
    step 9 $total "Ping test"
    if ping -c 3 -W 3 "$tunnel_server" &>/dev/null; then
        ok "Ping OK!"
    else
        local client_iface client_route client_ss client_nc
        local server_wg server_iptables server_nft server_route server_ping server_rp
        local client_wg_late client_route_svr client_rule

        client_iface=$(bash_exec "ip addr show ${wg_name} 2>/dev/null || echo 'interface not found'" 2>/dev/null || echo "")
        client_route=$(bash_exec "ip route get ${tunnel_server} 2>/dev/null || echo 'no route'" 2>/dev/null || echo "")
        client_nc=$(bash_exec "nc -zv -u -w 3 ${ip} ${port} 2>&1 || echo 'port unreachable'" 2>/dev/null || echo "")
        client_ss=$(sudo ss -lnup 2>/dev/null || echo "ss failed")
        server_wg=$(ssh "root@${ip}" "sudo wg show 2>&1 || echo 'wg show failed'" 2>/dev/null || echo "")
        server_iptables=$(ssh "root@${ip}" "sudo iptables -L INPUT -v -n --line-numbers 2>/dev/null || echo 'iptables show failed'" 2>/dev/null || echo "")
        server_nft=$(ssh "root@${ip}" "sudo nft list ruleset 2>/dev/null || echo 'nft not available'" 2>/dev/null || echo "")
        server_route=$(ssh "root@${ip}" "ip route get ${tunnel_server} 2>/dev/null || echo 'no route'" 2>/dev/null || echo "")
        server_ping=$(ssh "root@${ip}" "ping -c 2 -W 2 ${tunnel_server} 2>&1 || echo 'self ping failed'" 2>/dev/null || echo "")
        server_rp=$(ssh "root@${ip}" "sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.\"${wg_name}\".rp_filter 2>/dev/null || echo 'rp_filter check failed'" 2>/dev/null || echo "")
        client_wg_late=$(sudo wg show 2>/dev/null || echo "wg show failed")
        client_route_svr=$(bash_exec "ip route get ${ip} 2>/dev/null || echo 'no route'" 2>/dev/null || echo "")
        client_rule=$(bash_exec "ip rule show 2>/dev/null || echo 'no rules'" 2>/dev/null || echo "")

        serror "ping failed"
        serror "--- local interface ---\n${client_iface}--- route ---\n${client_route}--- nc ---\n${client_nc}--- ss ---\n${client_ss}--- remote wg ---\n${server_wg}--- remote iptables INPUT ---\n${server_iptables}--- remote nftables ---\n${server_nft}--- remote route get ---\n${server_route}--- remote self ping ---\n${server_ping}--- remote rp_filter ---\n${server_rp}--- client wg late ---\n${client_wg_late}--- client route to server ---\n${client_route_svr}--- client ip rule ---\n${client_rule}"
        swarn "Check:"
        swarn "  1) Server firewall UDP ${port} open"
        swarn "  2) iptables PostUp rules active"
        return 1
    fi

    # ---- 10 ----
    step 10 $total "SSH key exchange"
    key_exchange "$ip" || true

    ok "WireGuard deployed!"
    info "Server pubkey: ${server_pub}"
    info "Client IP: ${tunnel_client}"
    info "SSH tunnel: ssh lkf@${tunnel_server}"
    sdebug "deploy_wireguard done"
}

main() {
    local args=("$@")

    if [[ ${#args[@]} -eq 0 ]]; then
        show_usage
    fi

    if [[ " ${args[*]} " =~ --help ]]; then
        show_usage
    fi

    if [[ " ${args[*]} " =~ --switch ]]; then
        local idx=0
        for ((i = 0; i < ${#args[@]}; i++)); do
            if [[ "${args[$i]}" == "--switch" ]]; then
                idx=$((i + 1))
                break
            fi
        done
        if [[ $idx -lt ${#args[@]} ]]; then
            switch_wireguard "${args[$idx]}"
            return $?
        else
            serror "--switch requires an IP argument"
            return 1
        fi
    fi

    local ip tunnel_server tunnel_client subnet dir port

    ip=$(parse_arg_or_env "server-ip" "$DEFAULT_WG_IP")
    port=$(parse_arg_or_env "port" "$DEFAULT_WG_PORT")
    dir=$(parse_arg_or_env "dir" "$DEFAULT_WG_DIR")
    tunnel_server=$(parse_arg_or_env "tunnel-srv" "$DEFAULT_WG_SERVER_IP")
    tunnel_client=$(parse_arg_or_env "tunnel-cli" "$DEFAULT_WG_CLIENT_IP")
    subnet=$(parse_arg_or_env "subnet" "$DEFAULT_WG_SUBNET")

    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            --server-ip)   i=$((i + 1)); ip="${args[$i]}" ;;
            --port)        i=$((i + 1)); port="${args[$i]}" ;;
            --dir)         i=$((i + 1)); dir="${args[$i]}" ;;
            --tunnel-srv)  i=$((i + 1)); tunnel_server="${args[$i]}" ;;
            --tunnel-cli)  i=$((i + 1)); tunnel_client="${args[$i]}" ;;
            --subnet)      i=$((i + 1)); subnet="${args[$i]}" ;;
        esac
        i=$((i + 1))
    done

    deploy_wireguard "$ip" "$port" "$dir" \
        "$tunnel_server" "$tunnel_client" "$subnet"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
