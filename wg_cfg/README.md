# wg_cfg

WireGuard VPN 一键部署脚本

## 执行流程

```
默认 (部署 VPN):
1. server_install_and_config
   ├─ ssh 到远程服务器
   ├─ 安装 wireguard-tools
   ├─ 生成服务端密钥对
   └─ 写入 /etc/wireguard/wg0.conf (NAT + 转发)

2. server_fetch_pubkey
   └─ 从远程获取服务端公钥

3. local_configure
   ├─ 安装 wireguard-tools
   ├─ 生成本地密钥对
   └─ 写入 /etc/wireguard/wg0.conf (AllowIPs=0.0.0.0/0 全流量走 VPN)

4. server_exchange_key
   └─ 将本地公钥写入服务端 wg0.conf

5. server_start → 远程启动 wg-quick

6. local_start → 本地启动 wg-quick

7. verify_connectivity
   └─ ping 10.0.0.1 验证连通

clash 模式:
1. wg_clash <wg-server-ip>
   └─ 生成 Clash 配置 (/etc/clash/config.yaml)
      流量通过 WG-VPN(DIRECT) 出口，WG 隧道自动接管
```

## 目录结构

```
main.sh
lib/
  log.sh       # 彩色日志
  install.sh   # 安装 wireguard-tools
  keys.sh      # 密钥生成
  server.sh    # 服务端配置
  local.sh     # 本地配置
  verify.sh    # 连通性验证
  clash.sh     # Clash 配置生成
```

## 用法

```bash
# 一键部署 VPN
bash main.sh <server-ip> [ssh-port]

# 生成 Clash 配置 (流量走 WG 隧道)
bash main.sh clash <wg-server-ip> [输出文件]
```

## 网络拓扑

```
本地 Clash :7897 ──→ WG-VPN (DIRECT) ──→ wg0 :51820 ──→ 服务器 :51820
                                                    └──→ 公网 (NAT)
```
