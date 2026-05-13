# reinstall_system

Manjaro 系统重装自动化脚本

## 功能

一键配置新装系统的各项环境：

- 免密码 sudo
- 镜像源 (China)
- 系统服务 (fstrim, timedatectl)
- 显示器刷新率
- Git / SSH / GPG 配置
- Shell rc 注入
- Shadowsocks 代理
- 系统包 + AUR 包安装
- 输入法 (fcitx5)
- 字体
- 开机自启
- 系统更新

## 目录结构

```
main.sh
lib/
  sudo_nopassword.sh
  display_rate.sh
  git_config.sh
  ssh_config.sh
  gpg_gen.sh
  source_shrc.sh
  ss_proxy_config.sh
  auto_start.sh
```

## 用法

```bash
bash main.sh
```
