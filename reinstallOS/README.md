# reinstallOS

Manjaro/Arch Linux 系统重装后一键初始化工具。

## 关联文件

- file://src/cli.rs — CLI 子命令定义
- file://src/lib.rs — 命令分发入口
- file://src/run_cmd.rs — 命令执行封装
- file://src/slog.rs — 日志宏
- file://src/sf_link_mk.rs — 软链接创建工具
- file://src/cmd/ — 各子命令模块

## 命令

| 命令 | 功能 |
|------|------|
| `theme` | 应用 Breath Dark 主题 |
| `sudo-nopassword` | 配置免密 sudo |
| `mirrors` | 设置中国镜像源 |
| `fstrim` | 启用 fstrim.timer |
| `timezone [TZ]` | 设置时区 |
| `chown` | 修复 /data 权限 |
| `display <output> <rate>` | 设置显示器刷新率 |
| `ssh [email]` | 生成 SSH 密钥 |
| `gpg <name> <email>` | 生成 GPG 密钥 |
| `git [--name] [--email]` | 配置 git 全局设置 |
| `zshrc [rc_file]` | 注入 shell rc 源码块 |
| `packages` | 安装预定义系统包 |
| `aur` | 安装 AUR 包 |
| `fcitx5` | 安装配置 Fcitx5 输入法 |
| `autostart <apps...>` | 配置开机自启（支持 which 查找） |
| `update` | 系统 + AUR 更新 |
| `pacman-cfg` | 添加 archlinuxcn 源 |
| `shadowsocks <ip> [--deploy] [--local]` | Shadowsocks 部署/配置 |

## 构建

```bash
cargo build --release
```

## 使用

```bash
reinstall_os [选项] <命令>
  -n, --dry-run    模拟执行
```
