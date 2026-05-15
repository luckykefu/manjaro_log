# SSH 反向代理 — 远程控制本机

## 架构

```
本机 (NAT 内)                   远程服务器 (公网)
┌─────────────────┐     SSH     ┌──────────────────┐
│  lkf@manjaro     │───────────→│  root@202.182.112.91  │
│                   │  隧道      │                    │
│  :22   (SSHD)    │←──:2222──│  localhost:2222     │
└─────────────────┘            └──────────────────┘
```

## 隧道命令

建立隧道（本机执行）：

```bash
ssh -N -R 2222:localhost:22 root@202.182.112.91
```

## 远程操作（远程服务器执行）

```bash
# SSH 执行命令
ssh -p 2222 lkf@localhost "command"

# SCP 传文件
scp -P 2222 file lkf@localhost:/path/

# SCP 拉文件
scp -P 2222 lkf@localhost:/path/file .
```

## 持久化（autossh）

```bash
sudo pacman -S --noconfirm autossh

autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
  -N -R 2222:localhost:22 root@202.182.112.91
```

## 远程服务器 SSH 公钥

已添加至本机 `~/.ssh/authorized_keys`：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUx2zQPgu5rRWDc3TUyCEBBPLi0R/rnNoDHbvJqvxuw opencode-remote
```
