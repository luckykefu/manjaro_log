# opencode 使用指南

## 安装

```bash
install_opencode() {
    # [ -x ... ] 判断文件存在且可执行；|| 表示不存在才执行安装
    [ -x ~/.opencode/bin/opencode ] || curl -fsSL https://opencode.ai/v2/install | bash
    # ~ 是当前用户家目录（/root 或 /home/xxx）
}

install_opencode
```

## Rust skill 安装

### Skill 存放目录

| 位置                         | 作用域             |
| ---------------------------- | ------------------ |
| `~/.config/opencode/skills/` | 全局(所有项目)     |
| `.opencode/skills/`          | 项目级(git 仓库内) |

每个 skill 是一个文件夹,内含 `SKILL.md`,frontmatter 需包含 `name` 和 `description`。

### 安装推荐 Skill 仓库

```bash
# 1. leonardomso/rust-skills —— 265 条规则、渐进式加载(最流行)
git clone https://github.com/leonardomso/rust-skills.git ~/.config/opencode/skills/rust-skills

```

### 项目级安装(仅某项目使用)

```bash
git clone https://github.com/leonardomso/rust-skills.git .opencode/skills/rust-skills
```
