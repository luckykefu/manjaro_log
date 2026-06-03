# Tailscale 
```bash
cd
curl -fsSL https://opencode.ai/install | bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''
cat ~/.ssh/id_ed25519.pub > id
# 下载id
cat ~/Downloads/id >> ~/.ssh/authorized_keys
```

## 安装

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

## 启动


```bash
# 正常启动
sudo tailscaled up --ssh
# 容器无 TUN 设备
sudo tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &

tailscale --socket=/run/tailscale/tailscaled.sock up --authkey="${TS_AUTHKEY}"
# 在 <https://login.tailscale.com/admin/acls> 中将 POLICY/Tailscale SSH 策略改为：
# `Check mode : Off`
# ```json
# {
#   "action": "accept",
#   "src": ["autogroup:member"],
#   "dst": ["autogroup:self"],
#   "users": ["autogroup:nonroot", "root"]
# }
```

```bash
cat > ~/AGENTS.md << EOF
## 角色

你是远程服务器
请用 ssh lkf@100.75.45.53 连接我的电脑(我的电脑在远程,ssh 密钥可用)
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
EOF
.opencode/bin/opencode
```
