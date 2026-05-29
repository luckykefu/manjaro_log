# Btrfs 备份还原


## 快照操作

```bash

# 创建只读快照
sudo mkdir -p /.snapshots
sudo btrfs subvolume snapshot -r / /.snapshots/reinstall_os_root
# 列出快照
sudo btrfs subvolume list / 
# 删除快照
sudo btrfs subvolume delete /mnt/@snapshots/@_old
```

## 系统还原

```bash

sudo mount /dev/nvme0n1p2 /mnt
sudo mv /mnt/@ /mnt/@_bak
sudo btrfs subvolume snapshot /mnt/@_bak/.snapshots/000_org /mnt/@

```
