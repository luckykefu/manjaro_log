# Tailscale 配置 — 零配置双向组网

## 原理

```
你本地 ─── STUN 打洞 ─── 远程服务器
   │                        │
   └─────── Tailscale 控制面 ────────┘
                 (login.tailscale.com)
```

- **控制面**：登录认证，分配密钥（不经过流量）
- **STUN 打洞**：自动穿透 NAT，两端直连
- **WireGuard**：底层加密隧道，端到端加密

不需要公网 IP、端口转发、防火墙配置、证书交换。

---

## 安装与配置

### 两端都执行

```bash
# 安装
sudo pacman -S tailscale

# 启动服务
sudo systemctl enable --now tailscaled

# 登录认证（会弹出浏览器）
sudo tailscale up
```

浏览器访问输出的 URL，登录 GitHub/Google 账号即可。

### 验证连接

```bash
# 查看本机 Tailscale IP
tailscale ip
# → 100.x.x.x

# 查看所有设备
tailscale status
# → 100.89.108.56   vultr       user@   linux
# → 100.112.243.17  lkf-ms7d90  user@   linux

# 互 ping 测试
ping 100.112.243.17
ping 100.89.108.56
```

---

## 日常使用

```bash
# SSH 双向连接
ssh root@100.89.108.56          # 本地 → 远程
ssh lkf@100.112.243.17          # 远程 → 本地

# 文件互传
scp file root@100.89.108.56:~/
scp file lkf@100.112.243.17:~/
rsync -avz root@100.89.108.56:/data/ /data/

# 访问 Web 服务
curl http://100.112.243.17:8080  # 远程访问本地服务
curl http://100.89.108.56:9090   # 本地访问远程服务
```

---

## 与 Shadowsocks 共存

| 工具 | 用途 | 方向 |
|------|------|------|
| **Shadowsocks** | 代理上网 | 本地 → 远程 → Internet |
| **Tailscale** | 组网互访 | 双向直连 |

两者互不冲突，各自独立运行。

---

## 常用命令

```bash
tailscale status          # 查看在线设备
tailscale ip              # 查看本机 IP
tailscale ping 100.x.x.x  # 测试打洞方式（direct/relay）
sudo tailscale down       # 断开连接
sudo tailscale up         # 重新连接
```

## 注意事项

- 各端需登录同一账号才能互通
- 默认只分配 IPv4 100.x.x.x 地址（IPv6 可选）
- 首次连接可能走 DERP 中继（延迟略高），几秒后自动切换为直连
- 无需开放任何防火墙入站端口（只需 UDP 出站）
