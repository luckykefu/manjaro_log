#!/bin/bash

set -euo pipefail

ssh_copy_id() {
    local ip="${1:?ip required}"
    local pass="${2:?password required}"
    [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || echo "无效 IP：$ip"
    local key="$HOME/.ssh/id_ed25519"
    [[ -f "$key" ]] || ssh-keygen -t ed25519 -N "" -f "$key"
    ssh-keygen -R "$ip" 2>/dev/null || true
    sshpass -p "$pass" ssh-copy-id \
        -o StrictHostKeyChecking=accept-new \
        -i "${key}.pub" \
        "root@${ip}" \
        || { echo "ssh_copy_id failed: $ip" >&2; return 1; }
    echo "ssh_copy_id done: $ip"
}

create_instance() {
    : "${VULTR_API_KEY:?}" "${TS_AUTHKEY:?}"
    local base="${API_BASE_URL:-https://api.vultr.com/v2}"
    local region="${1:-sgp}" plan="${2:-vc2-1c-1gb}" os_id="${3:-535}"

    local default_password
    default_password=$(curl "$base/instances" -X POST \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg r "$region" --arg p "$plan" --argjson o "$os_id" '{region:$r,plan:$p,os_id:$o,backups:"disabled"}')" | jq -r '.instance.default_password')  && echo "$default_password"

    local instance_id
    instance_id=$(curl -s "$base/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[]?.id')
    [[ "$instance_id" != "null" ]] && echo "$instance_id" || { echo "Creation failed:"; exit 1; }

    # 轮询获取 IP
    local ip=""
    for i in {1..30}; do
        sleep 3
        ip=$(curl -s "$base/instances/$instance_id" -H "Authorization: Bearer $VULTR_API_KEY" \
            | jq -r '.instance.main_ip // empty')
        [[ -n "$ip" && "$ip" != "0.0.0.0" ]] && echo "$ip" && break
        echo "Waiting for IP... ($i/30)"
    done

    [[ -n "$ip" ]] || { echo "Timeout waiting for IP"; exit 1; }

    echo "Instance $instance_id ready at $ip"

    # 从本地公钥部署（推荐方式）
    sudo pacman -S --noconfirm --needed sshpass &> /dev/null
    ssh_copy_id "$ip" "$default_password"
    # 执行远程部署
    ssh "root@$ip" bash -s << 'EOF'
        set -euxo pipefail
        curl -fsSL https://opencode.ai/install | bash
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo systemctl enable --now tailscaled
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        tailscale up --authkey="${TS_AUTHKEY}"

EOF
    echo "Deployment completed for $ip"

    ssh "root@$ip" 'cat > AGENTS.md << EOF
    ## 角色
    你是远程服务器
    请用 ssh -o StrictHostKeyChecking=accept-new lkf@100.75.45.53 连接我的电脑(我的电脑在远程,ssh 密钥可用)
    传输文本方式: 写入本地,scp
    禁止在开发阶段使用--release
    用户所有的路径都是远程路径

    ## 开发规范
    1. 编码前先思考
    不要预设。不要掩饰困惑。摆明权衡取舍。
    2. 简洁至上
    用最少的代码解决问题。不做任何推测性开发。
    3. 外科手术式改动
    只动必须动的地方。只清理你自己造成的混乱。
    4. 目标驱动执行
    定义成功标准。循环迭代直到验证通过。

    ## rust 开发相关:
    异步:tokio
    并行:rayon
    错误:thiserror/anyhow
    缓存:mock/fred
    日志:tracing
    反序列:serde
EOF'
    ssh "root@$ip" "ls AGENTS.md"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    create_instance "$@"
fi
