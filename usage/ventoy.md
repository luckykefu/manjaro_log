# Ventoy 使用指南

> Ventoy 是一个开源工具，用于创建可启动 USB 驱动器。与传统的写入方式不同，Ventoy 安装后，只需将 ISO/WIM/IMG/VHD(x)/EFI 文件复制到 U 盘即可启动，无需重复格式化。

## 安装

```bash
# Manjaro/Arch
sudo pacman -S ventoy --needed --noconfirm

# 或从官网下载
# https://github.com/ventoy/Ventoy/releases
```

## 基本使用

### 1. 查看 U 盘设备

```bash
lsblk
# 或
sudo fdisk -l
```

> ⚠️ 确认设备号（如 `/dev/sdb`），**不要选错磁盘**，否则会数据丢失！

### 2. 安装 Ventoy 到 U 盘

```bash
# 安全安装（若已安装 Ventoy 则报错退出）
sudo ventoy -i /dev/sda

# 强制安装（无论是否已安装）
sudo ventoy -I /dev/sda

# 使用 GPT 分区表（默认 MBR）
sudo ventoy -i -g /dev/sda

# 安装并保留尾部空间（单位 MiB，用于存放其他文件）
sudo ventoy -i -r 1024 /dev/sda

# 设置磁盘标签
sudo ventoy -i -L MYVENTOY /dev/sda

# 非破坏性安装（尝试保留已有数据，不保证成功）
sudo ventoy -i -n /dev/sda
```

### 3. 更新 Ventoy

```bash
# 更新 U 盘上的 Ventoy（保留已有 ISO 文件）
sudo ventoy -u /dev/sda
```

### 4. 查看 Ventoy 信息

```bash
sudo ventoy -l /dev/sda
```

### 5. 使用 U 盘

安装完成后，U 盘会被分为两个分区：

- **第1分区（exFAT）**：存放 ISO 文件的数据分区
- **第2分区（FAT）**：Ventoy 启动分区（隐藏）

**使用方式：**

1. 将 ISO 文件直接复制到 U 盘第1分区
2. 重启计算机
3. BIOS 中设置 USB 启动
4. Ventoy 菜单会列出所有 ISO 文件，选择即可启动

## 高级功能

### Secure Boot

```bash
# 启用 Secure Boot（默认启用）
sudo ventoy -i -s /dev/sda

# 禁用 Secure Boot
sudo ventoy -i -S /dev/sda
```

### 配置文件

在 U 盘第1分区创建 `ventoy/ventoy.json` 配置文件，可实现：

#### 菜单主题

```json
{
  "theme": {
    "file": "/ventoy/theme/theme.txt"
  }
}
```

#### 启动菜单别名

```json
{
  "menu_alias": [
    {
      "image": "/Arch-Linux-x86_64.iso",
      "alias": "Arch Linux"
    },
    {
      "image": "/ubuntu-24.04-desktop.iso",
      "alias": "Ubuntu 24.04"
    }
  ]
}
```

#### 自动安装（无人值守）

```json
{
  "auto_install": [
    {
      "image": "/ubuntu-24.04-desktop.iso",
      "template": "/ventoy/autoinstall/ubuntu-preseed.cfg"
    }
  ]
}
```

#### 持久化分区

```json
{
  "persistence": [
    {
      "image": "/ubuntu-24.04-desktop.iso",
      "backend": "/ventoy/persistence/ubuntu.dat"
    }
  ]
}
```

### 持久化数据

创建 ext4 镜像文件用于 Live USB 的数据持久化：

```bash
# 创建 4GB 持久化镜像
dd if=/dev/zero of=ubuntu.dat bs=1M count=4096
mkfs.ext4 ubuntu.dat
# 复制到 U 盘 /ventoy/persistence/ 目录
```

## 支持的镜像类型

| 类型          | 扩展名           |
| ------------- | ---------------- |
| ISO           | `.iso`           |
| 微软镜像      | `.wim`           |
| 软盘/硬盘镜像 | `.img`           |
| 虚拟硬盘      | `.vhd` / `.vhdx` |
| EFI 启动文件  | `.efi`           |

> 支持 1000+ 种操作系统，包括 Windows、Linux、ESXi、WinPE 等。

## 使用技巧

### 整理 ISO 文件

```
U 盘根目录/
├── Linux/
│   ├── ArchLinux-2025.iso
│   ├── Ubuntu-24.04.iso
│   └── Debian-12.iso
├── Windows/
│   ├── Win11_24H2.iso
│   └── Win10_22H2.iso
├── Tools/
│   ├── GParted.iso
│   ├── Clonezilla.iso
│   └── MemTest86.iso
└── ventoy/
    └── ventoy.json
```

> Ventoy 支持多级目录，自动递归扫描所有 ISO 文件。

### 多系统启动

一个 U 盘可同时存放多个 ISO：

- 多个 Linux 发行版
- Windows 安装镜像
- 救援/维护工具
- PE 系统

### 注意事项

1. ⚠️ 安装 Ventoy 会**清空 U 盘所有数据**
2. ⚠️ 确认设备号后再执行安装命令，避免误操作
3. exFAT 分区单个文件最大支持 16EB，适合存放超大镜像
4. 部分老旧 BIOS 可能不兼容 GPT 分区，此时使用 MBR
5. 更新 Ventoy 不会删除已有 ISO 文件
6. 若遇到启动问题，尝试关闭 Secure Boot

## 常见问题

### Q: 启动后黑屏或无法进入菜单？

A: 尝试禁用 Secure Boot，或使用 MBR 分区重新安装。

### Q: 某个 ISO 无法启动？

A: 检查 Ventoy 官网的兼容性列表，或更新 Ventoy 到最新版本。

### Q: 如何卸载 Ventoy？

A: 直接格式化 U 盘即可，或使用 `sudo ventoy -I /dev/sda` 重新安装别的工具。

### Q: 如何添加更多类型的镜像？

A: 直接复制到 U 盘即可，Ventoy 支持递归扫描目录。

---

> 官方文档：https://www.ventoy.net  
> GitHub：https://github.com/ventoy/Ventoy
