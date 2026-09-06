# sing-box 代理部署

## 文件

| 文件                  | 用途                                                               |
| --------------------- | ------------------------------------------------------------------ |
| `01.instal.sh`        | 安装 sing-box（官方通用 install.sh）                               |
| `02.server_deploy.sh` | 生成服务端配置（SS + Trojan + Hysteria2），下载 rule-set，开放端口 |
| `03.convert.sh`       | 服务端配置 → 客户端配置（mixed/TUN），自动拉取 rule-set            |
| `04.start.sh`         | 启动/停止/重启 sing-box，包含端口检查 + 连通性测试                 |

## 服务端

```bash
# 安装并部署
bash 01.instal.sh
bash 02.server_deploy.sh

# 管理
bash 04.start.sh {start|stop|restart|status}
```

## 客户端

```bash
# 生成客户端配置（mixed 模式，SOCKS5+HTTP :1080）
bash 03.convert.sh <服务器IP>

# 或 TUN 全局 VPN 模式
bash 03.convert.sh -t <服务器IP>

# 指定输出路径（默认 /etc/sing-box/client.json）
bash 03.convert.sh <服务器IP> /path/to/config.json /path/to/client.json

# stdout 输出
bash 03.convert.sh <服务器IP> /path/to/config.json -

# 启动客户端并验证
bash 04.start.sh start /etc/sing-box/client.json
```

## 协议说明

| 协议        | 端口  | 传输     | 特点                   |
| ----------- | ----- | -------- | ---------------------- |
| Shadowsocks | 18388 | TCP      | 轻量，默认出口         |
| Trojan      | 8443  | TCP+TLS  | 兼容性好               |
| Hysteria2   | 8444  | UDP/QUIC | 抗 QoS，relay 下不稳定 |

`auto` selector 默认使用 Shadowsocks，可在 clash 面板或 API 中切换。

## 连通性测试

```bash
# HTTP 代理
curl -x http://127.0.0.1:1080 -4 https://www.google.com

# SOCKS5 代理
curl --socks5-hostname 127.0.0.1:1080 -4 https://www.google.com
```

## Tailscale

服务器通过 Tailscale 组网，客户端通过 Tailscale IP 连接（避免 GFW 拦截）。

```bash
tailscale status
# 100.104.198.21  ← 服务器
# 100.75.45.53    ← 本机
```
