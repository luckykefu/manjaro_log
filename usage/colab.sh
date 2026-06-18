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

## 启动 opencode
cat > AGENTS.md << 'EOF'
你是远程服务器
用户所有的路径都是远程路径

# Tailscale 文件传输示例

## 发文件

```bash
tailscale file cp /path/to/file <目标主机名或IP>:
```

## 收文件

```bash
tailscale file get <存放目录>
```
EOF

cat >> AGENTS.md << 'EOF'
## CHAT FORMAT

- LANG: CHINESE
- REPLY FMT:
  - 需求分析: ...
  - 解决方案:
    - 1.
    - 2.
    - 3.
    - 4. 用户补充
  - 征求用户确认再执行方案

## ENV

```toml
[env]
system="manjaro"
shell_rc="$HOME/.zshrc"
cpu="intel 12400f"
gpu="amd redeon rx 6750 GRE 12GB"
proxy=["socks5h://127.0.0.1:1080", "socks5h://127.0.0.1:7890"]
```
## 开发规范
1. 编码前先思考
   不要预设。不要掩饰困惑。摆明权衡取舍。
2. 简洁至上
   用最少的代码解决问题。不做任何推测性开发。
3. 外科手术式改动
   只动必须动的地方。只清理你自己造成的混乱。
4. 目标驱动执行
   定义成功标准。循环迭代直到验证通过。

## rust代码要求

- 工业级架构设计
- rs文件DOC完整
- 单元测试完整
- debug详细
- 文件职责单一性
- 函数和文件命名可读性高

## rust 开发流程

需求分析 -> 解决方案 -> 方案部署 -> cargo check -> cargo test -> cargo run -p xxx --release -- -c /path/config.toml -> cargo fmt

EOF
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
