#!/usr/bin/env bash
set -euo pipefail
# Tailscale

## 安装
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://tailscale.com/install.sh | sh

## 启动 Tailscale

TS_AUTHKEY=tskey-auth-kLLnbWoPCV11CNTRL-GJ2u4M73hq4Cacyu84NUq4S6fHe7EQZv
cd
start(){
    local TS_AUTHKEY=${1:?}
    local MODE=${2:-userspace}

    if [[ $MODE == tun ]]; then
        sudo systemctl enable --now tailscaled
        sudo tailscale up --ssh --authkey="${TS_AUTHKEY}"
    else
        nohup sudo tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &
        sudo tailscale --socket=/run/tailscale/tailscaled.sock up --ssh --authkey="${TS_AUTHKEY}"
    fi
}
start "$TS_AUTHKEY"

cat > AGENTS.md << 'EOF'
# 开发规范

## 聊天格式

- 需求分析: 拆解目标与约束
- 解决方案: 给出可选方案及权衡
- 征求用户确认再执行方案

## 远程服务器操作

```
remote_user=lkf
remote_ip=100.75.45.53 # tailscale ip -4

# 执行命令:
tailscale ssh "$remote_user@$remote_ip" "cmd"

# 传输文件:
# 用法: wput "$remote_user@$remote_ip" <src> [dst]
wput() {
  local ip=$(tailscale ip -4)
  local user=${USER:-root}
  local cmd
  printf -v cmd 'scp %s@%s:"%s" "%s"' "$user" "$ip" "$2"  "$3"
  tailscale ssh "$1" "$cmd"
}
```

## 环境

- 系统: manjaro
- shell_rc: $HOME/.zshrc
- CPU: Intel 12400F
- GPU: AMD Radeon RX 6750 GRE 12GB
- 代理: socks5h://127.0.0.1:1080, socks5h://127.0.0.1:7890

## 编码规范

1. 编码前先思考 — 不要预设、掩饰困惑；摆明权衡取舍
2. 简洁至上 — 用最少的代码解决问题，不做推测性开发
3. 外科手术式改动 — 只动必须动的，只清理自己造成的混乱
4. 目标驱动执行 — 定义成功标准，循环迭代直到验证通过

## Rust 代码要求

- 工业级架构设计
- rs 文件 DOC 完整
- 单元测试完整
- debug 详细
- 文件职责单一性
- 函数和文件命名可读性高
- edition = "2024"

## Rust 开发流程

需求分析 -> 解决方案 -> 方案部署
-> `cargo clipper -p <包名>`
-> `cargo check -p <包名>`
-> `cargo test -p <包名>`
-> `cargo run -p <包名> --release -- -c /path/config.toml`
-> `cargo fmt`
EOF
## 启动 opencode
.opencode/bin/opencode

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
