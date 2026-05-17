# Tailscale 配置 — 零配置双向组网


```bash
### 两端都执行
# 登录认证（会弹出浏览器）
sudo pacman -S --noconfirm --needed tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up

## 日常使用
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

## 常用命令

tailscale status          # 查看在线设备
tailscale ip              # 查看本机 IP
tailscale ping 100.x.x.x  # 测试打洞方式（direct/relay）
sudo tailscale down       # 断开连接
sudo tailscale up         # 重新连接

## 注意事项

# - 各端需登录同一账号才能互通
# - 默认只分配 IPv4 100.x.x.x 地址（IPv6 可选）
# - 首次连接可能走 DERP 中继（延迟略高），几秒后自动切换为直连
# - 无需开放任何防火墙入站端口（只需 UDP 出站）

```
