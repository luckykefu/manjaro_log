# Rust CLI 工具安装指南

## 安装

```bash
# 安装默认工具列表
bash install_cli_tools.sh

# 安装指定工具（覆盖默认列表）
bash install_cli_tools.sh bat fd ripgrep

# 导入函数后按需调用
source install_cli_tools.sh
install_rust_tools bat fd
```

## 工具列表

| 工具 | 用途 | 替代 | 示例 |
|------|------|------|------|
| bat | 文件查看（语法高亮） | cat | `bat file.rs` |
| fd | 文件查找 | find | `fd -e rs` |
| ripgrep (rg) | 文本搜索 | grep | `rg 'fn main'` |
| eza | 目录列表（颜色/图标） | ls | `eza -la --tree` |
| zoxide | 智能目录跳转 | cd / z | `z project` |
| git-delta | git diff 高亮 | git diff | `git diff`（自动生效） |
| procs | 进程查看 | ps | `procs rust` |
| dust | 磁盘占用分析 | du | `dust -r` |
| bottom (btm) | 系统监控 | htop | `btm` |

## Shell 补全（~/.zshrc）

```zsh
eval "$(bat --completion zsh)"
eval "$(fd --gen-completions zsh)"
eval "$(rg --generate complete-zsh)"
eval "$(eza --completions zsh)"
eval "$(zoxide init zsh)"
eval "$(procs --completion zsh)"
```

## git-delta 配置（~/.gitconfig）

```ini
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    line-numbers = true
    side-by-side = true
```
