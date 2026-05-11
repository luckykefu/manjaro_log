# sing-box 部署记录

## 节点信息

| | 本地 | 服务器 |
|---|---|---|
| 系统 | Manjaro | Manjaro |
| 公网 IP | - | 202.182.112.91 |
| 版本 | 1.13.11 | 1.13.11 |
| 二进制 | `/usr/local/bin/sing-box` | `/usr/local/bin/sing-box` |

## 服务端

### 配置 `/etc/sing-box/config.json`

```json
{
  "log": { "level": "info" },
  "inbounds": [{
    "type": "hysteria2",
    "listen": "0.0.0.0",
    "listen_port": 443,
    "users": [{ "password": "lkf.Vpn.mima3" }],
    "tls": {
      "enabled": true,
      "alpn": ["h3"],
      "certificate_path": "/etc/sing-box/cert.pem",
      "key_path": "/etc/sing-box/key.pem"
    }
  }],
  "outbounds": [{ "type": "direct" }]
}
```

### TLS 证书（自签，10年）

```bash
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
  -keyout /etc/sing-box/key.pem \
  -out /etc/sing-box/cert.pem \
  -days 3650 -nodes \
  -subj '/CN=202.182.112.91' \
  -addext 'subjectAltName=IP:202.182.112.91'
```

### 防火墙

```bash
ufw allow 443/udp
```

### systemd 服务

```bash
# 启动
systemctl enable --now sing-box

# 状态
systemctl status sing-box
```

---

## 本地客户端

### 配置 `/etc/sing-box/config.json`

```json
{
  "log": { "level": "info" },
  "dns": {
    "servers": [
      { "tag": "local",  "address": "223.5.5.5", "detour": "direct" },
      { "tag": "remote", "address": "8.8.8.8",   "detour": "hy2" }
    ],
    "rules": [
      { "geosite": ["cn"], "server": "local" },
      { "outbound": ["any"], "server": "local" }
    ],
    "final": "remote"
  },
  "inbounds": [{
    "type": "socks",
    "listen": "127.0.0.1",
    "listen_port": 1081,
    "users": []
  }],
  "outbounds": [
    {
      "tag": "hy2",
      "type": "hysteria2",
      "server": "202.182.112.91",
      "server_port": 443,
      "password": "lkf.Vpn.mima3",
      "tls": { "enabled": true, "insecure": true, "alpn": ["h3"] }
    },
    {
      "tag": "ss-lan",
      "type": "socks",
      "server": "192.168.0.103",
      "server_port": 7897
    },
    { "tag": "direct", "type": "direct" },
    {
      "tag": "fallback",
      "type": "urltest",
      "outbounds": ["hy2", "ss-lan"],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "3m",
      "tolerance": 50
    }
  ],
  "route": {
    "geoip":    { "path": "/etc/sing-box/geoip.db" },
    "geosite":  { "path": "/etc/sing-box/geosite.db" },
    "rules": [
      { "geosite": ["cn"],          "outbound": "direct" },
      { "geoip":   ["cn", "private"], "outbound": "direct" }
    ],
    "final": "fallback"
  }
}
```

### 规则库

```bash
# 需走代理下载
sudo curl -x socks5h://127.0.0.1:1080 -Lo /etc/sing-box/geoip.db \
  https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db
sudo curl -x socks5h://127.0.0.1:1080 -Lo /etc/sing-box/geosite.db \
  https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db
```

### 常用命令

```bash
# 启动
sudo sing-box run -c /etc/sing-box/config.json &

# 停止
sudo pkill -f "sing-box run"

# 验证配置
sing-box check -c /etc/sing-box/config.json

# 走代理
export ALL_PROXY=socks5h://127.0.0.1:1081
```

---

## 分流规则

| 流量 | 走向 |
|---|---|
| 国内 IP / 域名 | direct 直连 |
| 其他 | urltest 自动选 hy2 / ss-lan |
| hy2 故障 | 自动切换 ss-lan |

## 延迟对比

| 方案 | 延迟 |
|---|---|
| Shadowsocks | 1.03s |
| Hysteria2 | 0.58s |

## 待优化

- [ ] 申请域名，替换自签证书为 Let's Encrypt
- [ ] 配置 systemd 开机自启
