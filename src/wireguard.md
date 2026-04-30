# WireGuard 部署记录

## 节点信息

| | 本地 | 服务器 |
|---|---|---|
| 系统 | Manjaro | Manjaro |
| 公网 IP | - | 202.182.112.91 |
| 内网 IP | 10.0.0.2 | 10.0.0.1 |
| 监听端口 | - | 51820 |

## 密钥

| | 公钥 |
|---|---|
| 服务器 | `tm+3X2E8yTqH9E6F8dp+N6GytE8ZIua9LfMwuBJaPXs=` |
| 本地 | `OYDs6xt+Zk9B82NXv4VIVE8MO2+vSaUiyC7UwfA3TTg=` |

> 私钥分别存于 `/etc/wireguard/server_private` 和 `/etc/wireguard/local_private`

## 配置文件

### 服务器 `/etc/wireguard/wg0.conf`

```ini
[Interface]
PrivateKey = <服务器私钥>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = OYDs6xt+Zk9B82NXv4VIVE8MO2+vSaUiyC7UwfA3TTg=
AllowedIPs = 10.0.0.2/32
```

### 本地 `/etc/wireguard/wg0.conf`

```ini
[Interface]
PrivateKey = <本地私钥>
Address = 10.0.0.2/24

[Peer]
PublicKey = tm+3X2E8yTqH9E6F8dp+N6GytE8ZIua9LfMwuBJaPXs=
Endpoint = 202.182.112.91:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25
```

## 常用命令

```bash
# 启动
sudo systemctl start wg-quick@wg0

# 停止
sudo systemctl stop wg-quick@wg0

# 开机自启
sudo systemctl enable wg-quick@wg0

# 查看状态
sudo wg show

# 验证连通
ping 10.0.0.1
```

## 防火墙

服务器使用 ufw，需放行 51820/udp：

```bash
ufw allow 51820/udp
```

## 延迟测试

| 方案 | 平均延迟 |
|---|---|
| WireGuard | 205ms |
| 直连 | 202ms |

## 定位

WireGuard 用于内网互联，直连 `10.0.0.1` 访问服务器服务，不作为代理使用。
