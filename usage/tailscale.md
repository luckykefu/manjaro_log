# Tailscale 使用指南

基于 WireGuard 的零配置虚拟组网工具，让分布各地的设备像在同一局域网内互通。

## 安装

```bash
usage/tailscale.sh
```

## API 删除设备

1. https://login.tailscale.com/admin/settings/keys → 生成 API Key

```bash
# 4. 安全删除离线设备（本机确认 + API 匹配）：

export TS_KEY="tskey-api-k2E6p4F5Tq11CNTRL-dYbwk2MzTG61GdEBgy7dF66ZovBqRbb9U"
export TAILNET="kefu1820@gmail.com"
curl -s -u "$TS_KEY:" "https://api.tailscale.com/api/v2/tailnet/-/devices" | \
  jq -r '.devices[] | select(.connectedToControl == false) | .id' | \
  xargs -I{} sh -c 'echo "删除 {}"; curl -s -X DELETE -u "$TS_KEY:" -o /dev/null "https://api.tailscale.com/api/v2/device/{}"'

offline=$(tailscale status --json | jq -r '[.Peer[] | select(.Online == false) | .DNSName | rtrimstr(".")] | .[]') && echo $offline
```
