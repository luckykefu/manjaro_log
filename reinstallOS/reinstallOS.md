## display

```bash
kscreen-doctor -o

output=1
Modes=1
kscreen-doctor "output.${output}.mode.${Modes}"

```

## app cfg

```bash
sudo tailscale up

google-chrome-stable --proxy-server=http://127.0.0.1:7890


sudo mkdir -p /home/.snapshots
sudo btrfs subvolume snapshot /home /home/.snapshots/004_app_cfg
```
