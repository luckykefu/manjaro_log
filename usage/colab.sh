#!/usr/bin/env bash
set -euo pipefail

## 安装
[ -x ~/.opencode/bin/opencode ] || curl -fsSL https://opencode.ai/install | bash &> /dev/null
~/.opencode/bin/opencode -v

command -v tailscale || curl -fsSL https://tailscale.com/install.sh | sh &> /dev/null
tailscale -V

## 启动
TS_AUTHKEY=tskey-auth-kLLnbWoPCV11CNTRL-GJ2u4M73hq4Cacyu84NUq4S6fHe7EQZv
start(){
    local TS_AUTHKEY=${1:?}
    local MODE=${2:-userspace}

    if [[ $MODE == tun ]]; then
        nohup sudo tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &
        sudo tailscale --socket=/run/tailscale/tailscaled.sock up --ssh --authkey="${TS_AUTHKEY}"
    else
        sudo systemctl enable --now tailscaled
        sudo tailscale up --ssh --authkey="${TS_AUTHKEY}"
    fi
}
start "$TS_AUTHKEY" tun

remote_user=lkf
remote_ip=100.75.45.53 # tailscale ip -4
tailscale ssh "$remote_user@$remote_ip" "cat /data/.manjaro/AGENTS.md" > AGENTS.md
tail -5 AGENTS.md
~/.opencode/bin/opencode

## 如何设置 Tailscale SSH 自动认证

### 申请 auth key

# - 打开 https://login.tailscale.com/admin/settings/general
# - Keys
# - Auth keys
# - Generate auth key…

### 设置允许执行命令

# - 打开 https://login.tailscale.com/admin/acls
# - POLICY
# - Tailscale SSH
# - Edit rule
# - Check mode : Off

# ```json
# {
#   "action": "accept",
#   "src": ["autogroup:member"],
#   "dst": ["autogroup:self"],
#   "users": ["autogroup:nonroot", "root"]
# }
# ```
