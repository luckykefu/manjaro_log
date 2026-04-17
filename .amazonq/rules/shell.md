---
name: shell-skill
description: Shell 编码规范与技巧
---

# Shell Skill

## 规范
- 脚本首行加 `#!/usr/bin/env bash`
- 变量用 `${}` 包裹，字符串用双引号
- 用 `[[` 替代 `[` 做条件判断
- 函数名用 `snake_case`

## 常用技巧

```zsh
# 算术运算
s=$((180 + 20 * 3))

# 默认值
name=${1:-"default"}

# 字符串截取
file="strategy_Aberration_3d.fthypt"
echo ${file%.fthypt}   # 去掉后缀
echo ${file#strategy_} # 去掉前缀

# 数组
tfs=("1h" "4h" "1d")
for tf in "${tfs[@]}"; do echo $tf; done

# 命令结果赋值
files=$(ls *.py)

# 错误处理
set -e          # 遇错退出
set -u          # 未定义变量报错
set -o pipefail # 管道错误传递
```

## 调试
```zsh
set -x  # 打印每条执行命令
```
