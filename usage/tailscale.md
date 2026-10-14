# 安装 tailscale


```bash
#!/bin/bash

# ========== 1. 安装 tailscale ==========
install_tailscale() {
    # command -v 检查命令是否存在；不存在才执行官方安装脚本（输出可见）
    command -v tailscale || curl -fsSL https://tailscale.com/install.sh | sh
    # 用 -V 输出版本信息
    tailscale -V
}

install_tailscale
```


# 启动 tailscaled 守护进程

```bash
start_tailscaled() {
  local MODE="${1:---container}"
  case "$MODE" in
    --container)
      sudo killall tailscaled || true
      # --tun=userspace-networking: 不创建真实 TUN 网卡（容器必须）
      # --state: 状态文件路径，保存登录信息，重启免重新登录
      # --socks5-server: 本机 1055 端口开 SOCKS5 代理
      sudo nohup tailscaled --tun=userspace-networking \
        --state=/var/lib/tailscale/tailscaled.state \
        --socks5-server=localhost:1055 > /var/log/tailscaled.log 2>&1 &
      ;;
    --host)
      sudo systemctl enable --now tailscaled
      ;;
    *)
      echo "usage: start_tailscaled [--container|--host]" >&2; return 1 ;;
  esac
}

# 用法：start_tailscaled --container / start_tailscaled --host
```


# 上线 tailnet

```bash
tailscale_up() {
  local MODE="${1:---container}"
  local TS_AUTHKEY="${TS_AUTHKEY:-tskey-auth-kntP2EjRL411CNTRL-GkpejtYkZuK27sersA9wuKB8VrfZeukjD}"
  case "$MODE" in
    --container)
      sudo tailscale --socket=/run/tailscale/tailscaled.sock up \
        --accept-routes --accept-dns=false \
        --ssh --authkey="${TS_AUTHKEY}"
      ;;
    --host)
      sudo tailscale up \
        --accept-routes --accept-dns=false \
        --ssh --authkey="${TS_AUTHKEY}"
      ;;
    *)
      echo "usage: tailscale_up [--container|--host]" >&2; return 1 ;;
  esac
  echo "tailscale started ip: $(tailscale ip -4)"
}

# 用法：tailscale_up --container / tailscale_up --host
#   TS_AUTHKEY环境变量可覆盖默认key：TS_AUTHKEY=tskey-auth-... tailscale_up --host
```


## API 删除设备

1. https://login.tailscale.com/admin/settings/keys → 生成 API Key


### 查询离线设备


```bash
#!/bin/bash
tailscale status | grep offline
```


```bash
#!/bin/bash
TAILNET="${TAILNET:--}"
API_KEY="${API_KEY:-tskey-api-kwtqFvLJ1j11CNTRL-GaVAFRWu3iQWbQ7vhX8EhQ7oVodymrRT}"

# 用 API token（tskey-api-...），在 Admin Console → Settings → Keys 生成
# 可环境变量覆盖：TAILNET=... API_KEY=... list_offline_devices

list_offline_devices() {
  # 只读：查看将被删除的离线设备，确认无误再删
  curl -s -u "$API_KEY:" "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/devices" | \
    jq -r '.devices[] | select(.connectedToControl == false) | "\(.id)  \(.name)  lastSeen=\(.lastSeen)"'
}

delete_offline_devices() {
  # 删除所有 connectedToControl == false 的离线设备
  export API_KEY
  curl -s -u "$API_KEY:" "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/devices" | \
    jq -r '.devices[] | select(.connectedToControl == false) | .id' | \
    xargs -I{} sh -c 'echo "删除 {}"; curl -s -X DELETE -u "$API_KEY:" -o /dev/null -w " -> HTTP %{http_code}\n" "https://api.tailscale.com/api/v2/device/{}"'
}

list_all_devices() {
  # 验证删除结果
  curl -s -u "$API_KEY:" "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/devices" | \
    jq -r '.devices[] | "\(.name)  connected=\(.connectedToControl)"'
}

# 用法：
# list_offline_devices
# delete_offline_devices
# list_all_devices
```
