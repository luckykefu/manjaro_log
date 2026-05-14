# WireGuard 一键部署工具

## 关联文件

- file://src/main.rs
- file://src/lib.rs
- file://src/client.rs
- file://src/server.rs
- file://src/cmd.rs
- file://src/slog.rs

## 功能解释

自动化部署 WireGuard 服务端与客户端配置。本地生成 bash 脚本，通过 SCP 推送到远程服务端执行，替代逐条 SSH 命令，减少部署时间与网络故障点。

支持两种模式：

1. **部署模式** — 在远程服务端安装 wireguard-tools、配置防火墙、生成密钥、写入配置、启动服务，同时在本地生成客户端配置并启动
2. **切换模式** — 使用已有配置文件快速连接远程服务端，跳过完整部署流程

## 入参说明

### CLI 参数

| 参数 | 环境变量 | 默认值 | 类型 | 说明 |
|------|---------|--------|------|------|
| `--server-ip` | `WG_SERVER_IP` | `64.176.225.208` | String | 服务端公网 IP |
| `--port` | `WG_PORT` | `51820` | u16 | WireGuard UDP 端口 |
| `--dir` | `WG_DIR` | `/etc/wireguard` | String | 配置目录 |
| `--tunnel-srv` | `WG_TUNNEL_SERVER` | `10.0.0.1` | String | 隧道服务端 IP |
| `--tunnel-cli` | `WG_TUNNEL_CLIENT` | `10.0.0.2` | String | 隧道客户端 IP |
| `--subnet` | `WG_SUBNET` | `24` | String | 子网掩码位数 |
| `--switch` | — | — | String | 用已有配置连接（参数为 IP） |
| 返回 | | | | 部署/连接结果 |

### Library API

| 函数 | 入参 | 返回 | 说明 |
|------|------|------|------|
| `deploy_wireguard` | `&WireGuardConfig` | `Result<()>` | 10 步部署主流程 |
| `switch_wireguard` | `&str` | `Result<()>` | 用已有配置快速连接 |

### WireGuardConfig

| 字段 | 类型 | 说明 |
|------|------|------|
| `server_ip` | String | 服务端公网 IP |
| `port` | u16 | WireGuard UDP 端口 |
| `dir` | String | 配置目录 |
| `tunnel_server_ip` | String | 隧道服务端 IP |
| `tunnel_client_ip` | String | 隧道客户端 IP |
| `subnet` | String | 子网掩码位数 |

## ASCII图示处理逻辑

```
部署模式:

1 -> client::push_key                    SSH 公钥推送至服务端
2 -> client::ensure_tools                本地检查 wireguard-tools
3 -> server::run_init                    生成 init 脚本 → SCP → SSH 执行
      ├─ detect firewall type
      ├─ pacman -S wireguard-tools
      ├─ open UDP port (firewalld/ufw/iptables)
      ├─ wg genkey → privatekey + publickey
      └─ ip route get 1.1.1.1 → iface
      ← 返回 FIREWALL, SERVER_PRIV, SERVER_PUB, IFACE
4 -> client::gen_keys                    本地 wg genkey + wg pubkey
5 -> client::write_config                写入 /etc/wireguard/{name}.conf
6 -> server::run_apply                   生成 apply 脚本 → SCP → SSH 执行
      ├─ sysctl net.ipv4.ip_forward=1
      ├─ 清理旧 wg 接口
      ├─ 写入服务端 .conf (PostUp/PostDown iptables)
      └─ systemctl enable+restart wg-quick@{name}
7 -> client::save_server_pubkey          保存服务端公钥
8 -> client::start_wg                    清理旧接口 + systemctl restart
9 -> ping -c 3 -W 3 {tunnel_server_ip}   验证隧道连通性
10 -> client::key_exchange               双向 SSH 密钥交换
返回 -> 部署成功 / 错误信息

切换模式:

1 -> --switch IP → wg_name = ip.replace('.', '-')
2 -> client::switch_wg
      ├─ 检查 /etc/wireguard/{name}.conf 是否存在
      ├─ 清理旧 wg 接口
      └─ systemctl enable+restart wg-quick@{name}
3 -> ping -c 3 {tunnel_server_ip}
返回 -> 连接成功 / 错误信息
```

## 文件结构

```
src/
├── main.rs      CLI 入口 — 参数解析 + 模式分发
├── lib.rs       Runner — deploy_wireguard / switch_wireguard
├── client.rs    本地操作 — 工具检查/密钥/配置/启动/SSH 密钥管理
├── server.rs    远程操作 — 生成 bash 脚本 → SCP → SSH 执行
├── cmd.rs       命令执行 — run/sudo/bash_exec/scp/ssh
└── slog.rs      日志系统 — 级别控制/彩色输出/步骤进度
```

## 使用示例

```bash
# 部署到新服务端
cargo run -p wireguard -- --server-ip 66.245.217.51

# 指定端口和隧道 IP
cargo run -p wireguard -- --server-ip 66.245.217.51 --port 51821 --tunnel-cli 10.0.0.10

# 环境变量方式
WG_SERVER_IP=66.245.217.51 WG_PORT=51820 cargo run -p wireguard

# 用已有配置快速连接
cargo run -p wireguard -- --switch 66.245.217.51
```
