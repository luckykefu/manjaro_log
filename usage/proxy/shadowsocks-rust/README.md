# shadowsocks-rust

## 脚本说明

| 脚本 | 用途 | 用法 |
|------|------|------|
| `server.sh` | VPS端: 安装SS + 生成配置 + 启动服务 | 在VPS上执行 |
| `deploy_server.sh` | 推送server.sh到VPS并执行 | `deploy_server.sh <ip>` |
| `deploy_vps.sh` | 一键部署: 服务端 + 客户端 + 验证 | `deploy_vps.sh <ip>` |
| `client_cfg.sh` | 本地: 拉取配置 + 启动客户端 | `client_cfg.sh <ip>` |
| `ss_to_mihomo.sh` | SS配置转mihomo格式 | `ss_to_mihomo.sh <ip>` |
| `deploy_colab.sh` | 部署到Google Colab | `deploy_colab.sh <session>` |
| `shadowsocks_colab.sh` | Colab端服务脚本 | Colab内执行 |

## 快速开始

```bash
# 1. 部署服务端
proxy/shadowsocks-rust/deploy_server.sh <ip>

# 2. 配置本地客户端
proxy/shadowsocks-rust/client_cfg.sh <ip>

# 3. (可选) 转换为mihomo配置
proxy/shadowsocks-rust/ss_to_mihomo.sh <ip>
proxy/mihomo/start.sh --tun
```

## 配置信息

- 端口: `8388`
- 加密: `2022-blake3-aes-256-gcm`
- 本地代理: `socks5h://127.0.0.1:1080`
