# Tailscale

## 安装

```bash

TS_AUTHKEY=tskey-auth-kLLnbWoPCV11CNTRL-GJ2u4M73hq4Cacyu84NUq4S6fHe7EQZv
cd
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://tailscale.com/install.sh | sh
start(){
    local TS_AUTHKEY=${1:?}
    nohup sudo tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &
    sudo tailscale --socket=/run/tailscale/tailscaled.sock up --ssh --authkey="${TS_AUTHKEY}"
}
start_tun(){
    local TS_AUTHKEY=${1:?}
    sudo systemctl enable --now tailscaled
    sudo tailscaled up --ssh --authkey="${TS_AUTHKEY}"
}
start "$TS_AUTHKEY"

cat > AGENTS.md << EOF
你是远程服务器
请用 tailscale ssh lkf@100.75.45.53 连接我的电脑,执行命令
文本/文件传输方式: 写入本地,scp到远程,
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

EOF

.opencode/bin/opencode
```

## 如何设置 Tailscale SSH 自动认证

### 申请 auth key

- 打开 https://login.tailscale.com/admin/settings/general
- Keys
- Auth keys
- Generate auth key…

### 设置允许执行命令

- 打开 https://login.tailscale.com/admin/acls
- POLICY
- Tailscale SSH
- Edit rule
- Check mode : Off

```json
{
  "action": "accept",
  "src": ["autogroup:member"],
  "dst": ["autogroup:self"],
  "users": ["autogroup:nonroot", "root"]
}
```
