```bash
ip=64.176.225.208
bash reinstallOS/shadowsocks-rust/main.sh  "$ip"

ip=64.176.225.208
bash reinstallOS/shadowsocks-rust/ssh_copy_id.sh "$ip"

ssh root@$ip "sudo pacman -Syu --noconfirm"

ssh root@$ip "curl -fsSL https://opencode.ai/install | bash"
ssh root@$ip "sudo pacman -Sy --noconfirm --needed tailscale"
ssh root@$ip "sudo systemctl enable --now tailscaled"
ssh root@$ip "sudo tailscale up"
ssh root@$ip 'ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""'
pub=$(ssh root@$ip "cat ~/.ssh/id_ed25519.pub")
echo "$pub" >> ~/.ssh/authorized_keys

ssh root@$ip "reboot"

ssh root@$ip
.opencode/bin/opencode

# 你是远程服务器
# 请用 ssh  lkf@100.75.45.53。连接我的电脑(远程,ssh 密钥可用
# 传输文本方式: 写入本地,scp

```
