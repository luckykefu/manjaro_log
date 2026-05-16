# SSH 反向代理 — 远程控制本机

```bash
ip=202.182.112.91
ssh-reverse-proxy/ssh-reverse-proxy.sh $ip

```

## 远程操作（远程服务器执行）

```bash
# 你在远程服务器
# 我已经运行如下命令,建立ssh连接
ip=202.182.112.91
port=2345
sudo systemctl start sshd
ssh -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -N -R $port:localhost:22 root@$ip
# 后续开发都在本地服务器上,我的用户名:lkf
# 
```
