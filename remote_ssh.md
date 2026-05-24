```bash
ip=45.32.60.113
bash shadowsocks-rust/main.sh  "$ip"

ssh root@$ip "curl -fsSL https://opencode.ai/install | bash"
.opencode/bin/opencode
ssh root@$ip "sudo pacman -Syu --noconfirm"
ssh root@$ip "sudo pacman -S --noconfirm --needed tailscale"
ssh root@$ip "sudo systemctl enable --now tailscaled"
ssh root@$ip "sudo tailscale up"

ssh root@$ip "sudo systemctl enable --now sshd"

ssh root@$ip "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N \"\" -C \"opencode-server-key\""
pub=$(ssh root@$ip "cat ~/.ssh/id_ed25519.pub")
echo "$pub" >> ~/.ssh/authorized_keys
# 你是远程服务器
# 请用 ssh lkf@100.113.252.1 连接我的电脑(远程,ssh 密钥可用
# 访问 /data/nutilustrader 查看项目
# 传输文本方式: 写入本地,scp
```
