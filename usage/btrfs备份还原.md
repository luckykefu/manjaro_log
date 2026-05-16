# Btrfs 备份还原

## 基本概念

- **子卷 (subvolume)** — btrfs 的独立文件系统树，可单独快照
- **快照 (snapshot)** — 子卷的时间点副本，分为 RW(可读写) 和 RO(只读)
- **发送/接收 (send/receive)** — 将快照数据传输到另一个位置/设备

## 常用布局

```
@          — 根子卷 (mounted as /)
@home     — /home
@cache    — /var/cache
@log      — /var/log
@snapshots — 快照存放
```

## 快照操作

```bash

# 创建只读快照
sudo mkdir -p /.snapshots
sudo btrfs subvolume snapshot -r / /.snapshots/reinstall_os_root

sudo mkdir -p /home/.snapshots
sudo btrfs subvolume snapshot -r /home /home/.snapshots/reinstall_os_home

# 创建可读写快照
sudo btrfs subvolume snapshot /mnt/@ /mnt/@snapshots/@_dev

# 列出快照
sudo btrfs subvolume list / /home

# 删除快照
sudo btrfs subvolume delete /mnt/@snapshots/@_old
```

## 备份到外部磁盘 (send/receive)

### 全量备份

```bash
# 1. 创建只读快照
sudo btrfs subvolume snapshot -r /mnt/@ /mnt/@snapshots/@_20250101

# 2. 发送到外部磁盘
sudo btrfs send /mnt/@snapshots/@_20250101 | sudo btrfs receive /mnt/backup/
```

### 增量备份

```bash
# 1. 创建新快照
sudo btrfs subvolume snapshot -r /mnt/@ /mnt/@snapshots/@_20250102

# 2. 基于上一个快照做增量发送
sudo btrfs send -p /mnt/@snapshots/@_20250101 /mnt/@snapshots/@_20250102 \
  | sudo btrfs receive /mnt/backup/
```

### 备份到文件

```bash
# 发送到文件 (而非直接到另一个子卷)
sudo btrfs send /mnt/@snapshots/@_20250101 > /backup/@_20250101.btrfs

# 从文件还原
sudo btrfs receive /mnt/restore/ < /backup/@_20250101.btrfs

# 压缩备份
sudo btrfs send /mnt/@snapshots/@_20250101 | zstd > /backup/@_20250101.btrfs.zst

# 解压还原
zstd -dc /backup/@_20250101.btrfs.zst | sudo btrfs receive /mnt/restore/
```

## 系统还原

```bash
# 从 live USB 启动

# 挂载根分区
mount /dev/sdX1 /mnt

# 将损坏的子卷移走
sudo mv /mnt/@ /mnt/@_broken

# 从快照还原
sudo btrfs subvolume snapshot /mnt/@snapshots/@_20250101 /mnt/@

# 或删除后重新创建
sudo btrfs subvolume delete /mnt/@
sudo btrfs subvolume snapshot /mnt/@snapshots/@_20250101 /mnt/@
```

## 自动化工具

### snapper

```bash
# 安装
sudo pacman -S snapper

# 配置 (会自动创建 / 的快照配置)
sudo snapper -c root create-config /

# 手动创建快照
sudo snapper -c root create -d "before update"

# 列出快照
sudo snapper -c root list

# 查看差异
sudo snapper -c root status 10..11

# 还原
sudo snapper -c root undochange 10..11
```

### snap-pac (与 pacman 钩子集成)

```bash
# 安装
yay -S snap-pac

# pacman 安装/升级/卸载时自动创建快照
```

## 挂载选项推荐

```
compress=zstd:3,noatime,ssd,space_cache=v2,autodefrag
```

## 常用查看命令

```bash
# 查看子卷
sudo btrfs subvolume list /

# 查看磁盘使用
sudo btrfs filesystem usage /

# 查看压缩率
sudo btrfs filesystem show /

# 查看设备信息
sudo btrfs device usage /
```

## 无 Live USB 还原

### 方式一：GRUB 快照启动

Manjaro 默认启用 snapper，GRUB 菜单 → **Snapshots** → 选择目标快照 → 启动

### 方式二：set-default 切换默认子卷

```bash
# 查看各子卷 ID
sudo btrfs subvolume list /

# 切换默认子卷 (下次启动生效)
sudo btrfs subvolume set-default <ID> /
sudo reboot

# 切回原来的 @
sudo btrfs subvolume set-default <@的ID> /
sudo reboot
```

**示例：**
| ID | 子卷 | 说明 |
|----|------|------|
| 256 | `@` | 当前系统根 |
| 259 | `.snapshots/reinstall_os` | 目标回滚快照 |

```bash
# 切换到 reinstall_os 快照
sudo btrfs subvolume set-default 259 /
sudo reboot

# 切回原来的系统
sudo btrfs subvolume set-default 256 /
sudo reboot
```
