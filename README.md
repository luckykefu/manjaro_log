```bash
sudo pacman -S --noconfirm --needed opencode
# https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825
# 你在远程 可以用ssh lkf@10.0.0.2连接我本地
ssh -NR 10880:localhost:1080 root@66.245.217.51 
curl --socks5-hostname 127.0.0.1:10880
```
