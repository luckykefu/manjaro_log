# Tailscale 使用指南

基于 WireGuard 的零配置虚拟组网工具，让分布各地的设备像在同一局域网内互通。

## 安装

```bash
usage/tailscale.sh
```


## API 删除设备

1. https://login.tailscale.com/admin/settings/keys → 生成 API Key
2. 查询所有设备：

```bash
export TS_KEY="tskey-api-xxxxx"
export TAILNET="your-tailnet"

curl -s "https://api.tailscale.com/api/v2/tailnet/$TAILNET/devices" \
  -u "$TS_KEY:" | jq '.devices[] | {id, name, lastSeen}'
```

> ⚠️ 公开 API 的 `online` 字段永远为 `null`，无法判断在线/离线。

3. 删除指定设备：

```bash
curl -X DELETE "https://api.tailscale.com/api/v2/device/{deviceID}" \
  -u "$TS_KEY:"
```

4. 安全删除离线设备（本机确认 + API 匹配）：

```bash
# 1. 本机获取离线设备名（.Online 真实可靠）
offline=$(tailscale status --json | jq -r '[.Peer[] | select(.Online == false) | .DNSName | rtrimstr(".")] | .[]')

# 2. API 按名称匹配后删除
curl -s "https://api.tailscale.com/api/v2/tailnet/$TAILNET/devices" \
  -u "$TS_KEY:" | jq -r '.devices[] | "\(.id) \(.name)"' \
  | while read id name; do
      for off in $offline; do
        if [[ $name == "$off" ]]; then
          echo "Deleting $name ($id)"
          curl -X DELETE "https://api.tailscale.com/api/v2/device/$id" -u "$TS_KEY:"
        fi
      done
    done
```

5. 最安全的方式（推荐）：https://login.tailscale.com → Machines → 手动勾选删除

## 常见问题

- 跨运营商 / 对称 NAT 连接慢：可自建 DERP 中继服务器
- 与代理共存：`tailscale0` 虚拟网卡，互不影响
- 无需公网 IP、无需端口转发，自动 NAT 穿透
- 离线设备仍在 tailnet 中，需手动删除
