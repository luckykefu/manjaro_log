# shadowsocks_cfg

Shadowsocks 代理配置脚本

## 执行流程

```
deploy 模式:
1. ssh-copy-id → 推送公钥到远程服务器
2. scp server.sh → 上传服务端脚本
3. ssh 远程执行 server.sh
       ├─ 安装 shadowsocks-rust
       ├─ 写入 /etc/shadowsocks-rust/config.json
       ├─ 启动 systemd 服务
       └─ iptables 放行端口
4. proxy_config.sh (本地)
       ├─ scp 拉取服务端配置
       ├─ jq 转换为 sslocal 客户端配置
       └─ 启动 sslocal (端口 1080)

clash 模式:
1. scp 拉取服务端配置
2. yq 生成 Clash YAML (端口 7897)
3. 输出到指定文件

server 模式: 仅在远程执行服务端安装
```

## 目录结构

```
main.sh
lib/
  log.sh           # 日志函数
  deploy.sh        # 一键部署入口
  server.sh        # 服务端安装脚本
  proxy_config.sh  # 本地 sslocal 配置与启动
  clash.sh         # Clash 配置生成
```

## 用法

```bash
# 一键部署服务端 + 配置本地
bash main.sh deploy <ip> [port]

# 生成 Clash 配置
bash main.sh clash <ip>

# 仅远程部署服务端
bash main.sh server <ip> [port]
```

## 拓扑

```
远程服务器:8388 (ss-server)
       ↕
本地 sslocal :1080 (SOCKS5)
       ↕
Clash :7897 (HTTP/SOCKS5)
```
