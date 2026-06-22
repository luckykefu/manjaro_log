# 创建实例

```bash
    : "${VULTR_API_KEY:?}" "${TS_AUTHKEY:?}"
    local base="${API_BASE_URL:-https://api.vultr.com/v2}"
    local region="${1:-sgp}" plan="${2:-vc2-1c-1gb}" os_id="${3:-535}"

    local default_password
    default_password=$(curl "$base/instances" -X POST \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg r "$region" --arg p "$plan" --argjson o "$os_id" '{region:$r,plan:$p,os_id:$o,backups:"disabled"}')" | jq -r '.instance.default_password')  && echo "$default_password"
```

# 获取 ip

```bash
    local ip=""
    for i in {1..30}; do
        sleep 3
        ip=$(curl -s "$base/instances/$instance_id" -H "Authorization: Bearer $VULTR_API_KEY" \
            | jq -r '.instance.main_ip // empty')
        [[ -n "$ip" && "$ip" != "0.0.0.0" ]] && echo "$ip" && break
        echo "Waiting for IP... ($i/30)"
    done
```

# 部署 vpn

## 推送ssh密钥到远程

```bash
    # 从本地公钥部署（推荐方式）
    sudo pacman -S --noconfirm --needed sshpass &> /dev/null
    ssh_copy_id "$ip" "$default_password"
```

## 部署 shadowsocks server

```bash
proxy/shadowsocks-rust/deploy_server.sh "$ip"
```

## 本地配置 shadowsocks client

```bash
proxy/shadowsocks-rust/client_cfg.sh "$ip"
```

# 获取 instance_id

```bash
    local instance_id
    instance_id=$(curl -s "$base/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[]?.id')
    [[ "$instance_id" != "null" ]] && echo "$instance_id" || { echo "Creation failed:"; exit 1; }
```
