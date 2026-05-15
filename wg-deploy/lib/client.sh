#!/bin/bash
# lib/client.sh
# 客户端操作: 工具检查/密钥生成/配置写入/服务启动/SSH 密钥管理/切换模式
#
# 函数:
#   ensure_tools       - 确保本地已安装 wireguard-tools + openresolv
#   gen_keys           - 生成本地密钥对，返回公钥
#   write_config       - 写入客户端 .conf
#   start_wg           - 清理旧接口 + 启用 wg-quick
#   save_server_pubkey - 保存服务端公钥到本地
#   push_key           - ssh-copy-id 推送本地公钥到服务端
#   key_exchange       - 服务端生成密钥对，交换公钥到本地
#   switch_wg          - 用已有配置连接服务端

ensure_tools() {
    if ! command -v wg &>/dev/null; then
        sudo pacman -S --noconfirm --needed wireguard-tools openresolv
        sinfo "wireguard-tools openresolv installed"
    else
        sdebug "wg already present"
    fi
}

gen_keys() {
    local wg_dir=$1

    sudo mkdir -p "$wg_dir"
    local priv
    priv=$(sudo wg genkey) || return 1
    local pub
    pub=$(echo "$priv" | sudo wg pubkey) || return 1
    echo "$priv" | sudo tee "${wg_dir}/privatekey" > /dev/null
    echo "$pub" | sudo tee "${wg_dir}/publickey" > /dev/null
    sudo chmod 600 "${wg_dir}/privatekey"

    sinfo "client key pair generated"
    sdebug "client pubkey=${pub:0:16}..."
    echo "$pub"
}

write_config() {
    local wg_dir=$1 wg_name=$2 server_pub=$3
    local tunnel_client=$4 subnet=$5 tunnel_server=$6 cfg_ip=$7 cfg_port=$8

    local local_priv
    local_priv=$(sudo cat "${wg_dir}/privatekey") || return 1
    local_priv=$(echo "$local_priv" | xargs)

    local client_cfg="${wg_dir}/${wg_name}.conf"
    sdebug "client config: $client_cfg"

    sudo tee "$client_cfg" > /dev/null << WGEOF
[Interface]
Address = ${tunnel_client}/${subnet}
PrivateKey = ${local_priv}

[Peer]
PublicKey = ${server_pub}
Endpoint = ${cfg_ip}:${cfg_port}
AllowedIPs = ${tunnel_server}/32
PersistentKeepalive = 25
WGEOF

    sudo chmod 600 "$client_cfg"
    sinfo "client config written to $client_cfg"
}

start_wg() {
    local wg_name=$1

    sudo pacman -S --noconfirm --needed openresolv

    bash_exec "sudo wg show interfaces 2>/dev/null | xargs -r -I{} sh -c 'sudo systemctl stop wg-quick@{} 2>/dev/null; sudo wg-quick down {} 2>/dev/null; sudo ip link delete dev {} 2>/dev/null' || true" >/dev/null 2>&1 || true

    sudo systemctl enable "wg-quick@${wg_name}" || return 1
    sudo systemctl restart "wg-quick@${wg_name}" || return 1

    local local_wg
    local_wg=$(sudo wg show) || true
    sdebug "local wg:${local_wg:+
}${local_wg}"
    sinfo "client wg-quick@${wg_name} restarted"
}

save_server_pubkey() {
    local wg_dir=$1 server_pub=$2
    echo "$server_pub" | sudo tee "${wg_dir}/server_public_key" > /dev/null
    sinfo "server public key saved"
}

push_key() {
    local ip=$1
    sdebug "push_key ip=$ip"

    ssh-keygen -R "$ip" 2>/dev/null || true

    ssh-copy-id -o StrictHostKeyChecking=accept-new -i ~/.ssh/id_ed25519.pub "root@${ip}" || {
        serror "ssh-copy-id failed, push manually"
        return 1
    }
    sinfo "SSH public key copied to root@${ip}"
}

key_exchange() {
    local ip=$1
    sdebug "key_exchange ip=$ip"

    ssh "root@${ip}" "sudo pacman -S --noconfirm --needed sshpass" 2>/dev/null || true
    ssh "root@${ip}" "ssh-keygen -t ed25519 -C \"\" -f \"\$HOME/.ssh/id_ed25519\" -N \"\" 2>/dev/null || true" 2>/dev/null || true

    local remote_pubkey
    remote_pubkey=$(ssh "root@${ip}" "cat ~/.ssh/id_ed25519.pub") || {
        swarn "key_exchange: failed to get remote pubkey"
        return 0
    }

    echo "$remote_pubkey" >> ~/.ssh/authorized_keys
    sinfo "server SSH key added to local authorized_keys"
}

switch_wg() {
    local wg_name=$1 wg_dir=$2
    local config_path="${wg_dir}/${wg_name}.conf"

    if [[ ! -f "$config_path" ]]; then
        serror "config not found: $config_path, deploy first"
        return 1
    fi
    sdebug "switch_wg $config_path"

    bash_exec "sudo wg show interfaces 2>/dev/null | xargs -r -I{} sh -c 'sudo systemctl stop wg-quick@{} 2>/dev/null; sudo wg-quick down {} 2>/dev/null; sudo ip link delete dev {} 2>/dev/null' || true" >/dev/null 2>&1 || true

    sudo systemctl enable "wg-quick@${wg_name}" || return 1
    sudo systemctl restart "wg-quick@${wg_name}" || return 1

    local status
    status=$(sudo wg show) || true
    sdebug "wg status:${status:+
}${status}"
    sinfo "wg-quick@${wg_name} started"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "lib/client.sh — source this file in wg-deploy.sh"
fi
