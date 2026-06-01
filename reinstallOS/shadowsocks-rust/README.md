# shadowsocks-rust 一键部署

## 1. 推送 SSH 公钥（只需首次）
```bash
IP=207.148.70.143

ssh_copy_id "$IP"
```

## 2. 部署服务端

```bash
scp server_deploy.sh "root@${IP}":~
ssh "root@${IP}" "bash ~/server_deploy.sh"
```

## 3. 配置本地客户端

```bash
bash client_cfg.sh "$IP"
```
