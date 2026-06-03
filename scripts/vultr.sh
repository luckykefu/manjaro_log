#!/bin/bash
set -euo pipefail

# 从环境变量读取敏感信息
: "${VULTR_API_KEY:?}" "${TS_AUTHKEY:?}"   # Tailscale 预授权密钥
API_BASE_URL="https://api.vultr.com/v2"

# 清理所有实例（可选）
destroy_all_instances() {
    local ids
    ids=($(curl -s "$API_BASE_URL/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[]?.id'))

    if [[ ${#ids[@]} -eq 0 ]]; then
        echo "No instances found to delete."
        return 0
    fi

    for id in "${ids[@]}"; do
        echo "Deleting $id ..."
        if curl -X DELETE -H "Authorization: Bearer $VULTR_API_KEY" "$API_BASE_URL/instances/$id" -w "%{http_code}" -o /dev/null -s; then
            echo "Deleted $id"
        else
            echo "Failed to delete $id"
        fi
        sleep 1
    done
}

# 创建实例并等待 IP 就绪
create_instance() {
    local region="${1:-sgp}" plan="${2:-vc2-1c-1gb}" os_id="${3:-535}"
    echo "Creating instance in $region ..."
    local resp
    resp=$(curl "$API_BASE_URL/instances" -X POST \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg r "$region" --arg p "$plan" --argjson o "$os_id" '{region:$r,plan:$p,os_id:$o,backups:"disabled"}')")

    local instance_id
    instance_id=$(jq -r '.instance.id' <<< "$resp")
    if [[ "$instance_id" == "null" ]]; then
        echo "Creation failed:"; jq . <<< "$resp"
        exit 1
    fi

    # 轮询获取 IP
    local ip=""
    for i in {1..30}; do
        sleep 3
        ip=$(curl -s "$API_BASE_URL/instances/$instance_id" -H "Authorization: Bearer $VULTR_API_KEY" \
            | jq -r '.instance.main_ip // empty')
        [[ -n "$ip" ]] && break
        echo "Waiting for IP... ($i/30)"
    done

    if [[ -z "$ip" ]]; then
        echo "Timeout waiting for IP"
        exit 1
    fi

    echo "Instance $instance_id ready at $ip"
    default_password=$(jq -r '.instance.default_password' <<< "$resp")&& echo $default_password

    # 从本地公钥部署（推荐方式）
    sudo pacman -S --noconfirm --needed sshpass
    ssh_copy_id "$ip" $default_password
    # 执行远程部署
    ssh "root@$ip" bash -s << EOF
        set -euxo pipefail
        # # 安装 opencode
        # curl -fsSL https://opencode.ai/install | bash

        # # 启动 Tailscale 并认证
        # sudo pacman -Sy --noconfirm --needed tailscale
        # sudo systemctl enable --now tailscaled
        # ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
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
    ssh root@$ip "ls AGENTS.md"
}

# 主逻辑：支持 --destroy-all 和 --create
case "${1:-}" in
    --destroy-all) destroy_all_instances ;;
    --create) shift; create_instance "$@" ;;
    *) echo "Usage: $0 [--destroy-all | --create [region] [plan] [os_id]]" ;;
esac


# ip=$(curl -s "$API_BASE_URL/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[]?.main_ip')
# ssh root@$ip
# .opencode/bin/opencode
