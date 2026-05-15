```bash
curl -fsSL https://opencode.ai/install | bash
# https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825
# 你在远程 可以用ssh lkf@10.0.0.2连接我本地
ssh -N -R 2222:localhost:22 root@202.182.112.91
sudo pacman -S --noconfirm openssh && sudo systemctl enable --now sshd
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUx2zQPgu5rRWDc3TUyCEBBPLi0R/rnNoDHbvJqvxuw opencode-remote' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo "OK"
```
# ssh 反向代理步骤
ip=$1
ssh-keygen -R ip
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@{ip}
连接远程,生成ssh key,获取密钥
# 本地后台建立反向代理
将密钥写入认证keys
