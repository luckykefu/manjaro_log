# WireGuard 隧道配置 — 远程连接本地

## 架构

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│   本地 (L)    │────│  公网服务器 (S)   │────│   远程 (R)    │
│  10.0.0.2/24 │    │  10.0.0.1/24     │    │  10.0.0.3/24 │
│  Arch Linux  │    │  202.182.112.91  │    │  （任意 OS）  │
└──────────────┘    │  Arch Linux      │     └──────────────┘
                    │  UDP 51820       │
                    └──────────────────┘
```

- 公网服务器作为 Hub，转发流量并做 NAT
- 本地和远程通过 WireGuard 加密隧道直连服务器
- 远程通过服务器跳转到本地 (ssh user@10.0.0.2)

---

## 当前配置

### 公网服务器 (`/etc/wireguard/wg0.conf`)

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# 本地机器
PublicKey = MnD/u6ibn/+CrHc7BMQ7qBSIfleD81+k+fvPsyvbThc=
AllowedIPs = 10.0.0.2/32

[Peer]
# 远程机器（待添加）
PublicKey = <remote-public-key>
AllowedIPs = 10.0.0.3/32
```

### 本地 (`/etc/wireguard/wg0.conf`)

```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = <local-private-key>

[Peer]
PublicKey = 5qpqmosO61CHteB407WCxR5G5g3ziQJjNWVxYqi9MH0=
Endpoint = 202.182.112.91:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
```

---

## 远程机器配置步骤

### 1. 安装 WireGuard

```bash
# Arch Linux
sudo pacman -Sy wireguard-tools

# Debian/Ubuntu
sudo apt install wireguard

# RHEL/Fedora
sudo dnf install wireguard-tools
```

### 2. 生成密钥

```bash
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
sudo chmod 600 /etc/wireguard/privatekey
```

记录输出的公钥（远程公钥）。

### 3. 创建配置

```bash
LOCAL_PRIV=$(sudo cat /etc/wireguard/privatekey)

sudo tee /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.0.0.3/24
PrivateKey = ${LOCAL_PRIV}

[Peer]
PublicKey = 5qpqmosO61CHteB407WCxR5G5g3ziQJjNWVxYqi9MH0=
Endpoint = 202.182.112.91:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF
```

### 4. 在服务器上添加远程 Peer

在远程机器查看公钥：

```bash
cat /etc/wireguard/publickey
```

然后在本地或任意机器 SSH 到服务器添加：

```bash
ssh root@202.182.112.91 "tee -a /etc/wireguard/wg0.conf << 'PEER'

[Peer]
PublicKey = <远程公钥>
AllowedIPs = 10.0.0.3/32
PEER"

ssh root@202.182.112.91 "systemctl restart wg-quick@wg0"
```

### 5. 启动远程 WireGuard

```bash
sudo systemctl enable --now wg-quick@wg0
```

---

## 验证

```bash
# 远程 -> 服务器
ping 10.0.0.1

# 远程 -> 本地
ping 10.0.0.2

# SSH 连接本地
ssh user@10.0.0.2
```

---

## 一键脚本

在本地机器运行：

```bash
sudo ./wg_cfg.sh 202.182.112.91
```

自动完成：安装 WG → 生成密钥 → 配置服务器 → 配置本地 → 交换密钥 → 启动服务 → 开防火墙 → 验证连通。
