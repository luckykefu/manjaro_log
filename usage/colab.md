```bash
cd
curl -fsSL https://opencode.ai/install | bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''
cat ~/.ssh/id_ed25519.pub > id
# 下载id
cat ~/Downloads/id >> ~/.ssh/authorized_keys
```


## Tailscale 安装与启动

```bash
### 安装
curl -fsSL https://tailscale.com/install.sh | sh
```

### 启动

容器无 systemd，需手动启动 tailscaled，并使用 userspace-networking 模式（无 TUN 设备）：

```bash
mkdir -p /run/tailscale /var/lib/tailscale
tailscaled --state=/var/lib/tailscale/tailscaled.state \
  --socket=/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1080 &
sleep 2
tailscale --socket=/run/tailscale/tailscaled.sock up

https://login.tailscale.com/a/13fa778e014b9e
```

### SSH 连接问题
```bash
# 单次连接
ssh -o ProxyCommand="connect -S localhost:1080 %h %p" lkf@100.75.45.53

# 或写入 ~/.ssh/config 方便使用
cat >> ~/.ssh/config << 'CONF_EOF'

Host lkf-ms7d90
    HostName 100.75.45.53
    User lkf
    ProxyCommand connect -S localhost:1080 %h %p
    StrictHostKeyChecking accept-new
CONF_EOF


cat > AGENTS.md << EOF
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

配置后直接 `ssh lkf-ms7d90` 即可。
