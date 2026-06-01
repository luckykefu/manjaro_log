```bash
cd
curl -fsSL https://opencode.ai/install | bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''
cat ~/.ssh/id_ed25519.pub > id

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
```

### 认证

访问输出的 URL 完成登录。

### SSH 连接问题

直接用 `ssh lkf@100.75.45.53` 会连接超时。原因是：

- 容器中 Tailscale 使用 `userspace-networking` 模式（无 TUN 设备），**内核没有到 Tailscale IP 的路由**
- 普通 SSH 走内核网络栈，无法到达 100.x.x.x 地址

**解决方案**：通过 Tailscale 的 SOCKS5 代理转发 SSH 流量，绕过内核路由。

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
```

配置后直接 `ssh lkf-ms7d90` 即可。
