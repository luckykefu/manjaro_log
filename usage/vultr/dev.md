# 查询实例

无参数。输出格式: `[id] label | os | ip | status | ram | vCPU`

```bash
vultr_list_instances() {
    curl -s "https://api.vultr.com/v2/instances" \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        | jq -r '.instances[] | "[\(.id)] \(.label // .hostname) | \(.os) | \(.main_ip) | \(.status) | \(.ram/1024)GB | \(.vcpu_count)vCPU"'
}
```

# 创建实例

| 参数 | 默认值 | 说明 |
|------|--------|------|
| $1 region | nrt | 区域: nrt(东京), sgp(新加坡), ewr(新泽西) |
| $2 plan | vc2-1c-1gb | 套餐: vc2-1c-1gb(1vCPU/1GB), vc2-1c-2gb 等 |
| $3 os_id | 535 | 系统 ID: 535(Arch Linux), 164(Ubuntu 22.04) |

输出创建实例的默认密码。

```bash
vultr_create_instance() {
    local region="${1:-nrt}"
    local plan="${2:-vc2-1c-1gb}"
    local os_id="${3:-535}"

    curl -s "https://api.vultr.com/v2/instances" \
        -X POST \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg r "$region" \
            --arg p "$plan" \
            --argjson o "$os_id" \
            '{region:$r, plan:$p, os_id:$o, backups:"disabled"}')" \
        | jq -r '.instance.default_password'
}
```

# 推送ssh密钥到实例

| 参数 | 必填 | 说明 |
|------|------|------|
| $1 instance_id | 是 | 实例 ID |
| $2 password | 是 | 实例密码 |

依赖: `sshpass` (`pacman -S sshpass`)

```bash
vultr_push_sshkey() {
    local instance_id="${1:?需要 instance_id}"
    local password="${2:?需要 password}"

    local ip
    ip=$(curl -s "https://api.vultr.com/v2/instances/$instance_id" \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        | jq -r '.instance.main_ip')

    local pubkey
    pubkey=$(cat ~/.ssh/id_ed25519.pub)
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no root@"$ip" \
        "mkdir -p ~/.ssh && echo '$pubkey' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
}
```

# 销毁实例

| 参数 | 必填 | 说明 |
|------|------|------|
| $1 instance_id | 是 | 实例 ID |

```bash
vultr_delete_instance() {
    local instance_id="${1:?需要 instance_id}"

    curl -s "https://api.vultr.com/v2/instances/$instance_id" \
        -X DELETE \
        -H "Authorization: Bearer $VULTR_API_KEY"
}
```
