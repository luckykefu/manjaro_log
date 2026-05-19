# Shadowsocks-Rust Cargo 安装部署教程

## ssh 连接 远程电脑

```bash
local ip=64.176.225.208
bash reinstallOS_sh/shadowsocks-rust/ssh_copy_id.sh "$ip"
```

---

## 服务端部署（VPS）

```bash
scp shadowsocks-rust/server_deploy.sh "root@${ip}":server_deploy.sh
ssh "root@${ip}" "bash server_deploy.sh"
```

---

## 客户端部署（本地）

```bash
# 从远程拉去配置 get_remote_cfg
# jq 修改配置 setup_cfg
# 启动 start
# 验证
bash shadowsocks-rust/client_cfg.sh $ip
```
