# shadowsocks-rust 一键部署

## 2. 部署服务端

```bash
proxy/shadowsocks-rust/deploy_server.sh "$ip"
```

## 3. 配置本地客户端

```bash
proxy/shadowsocks-rust/client_cfg.sh "$ip"
proxy/shadowsocks-rust/tun.sh stop
```
