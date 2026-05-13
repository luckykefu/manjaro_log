# Shell 编码规范
## 语法
- `[[ ]]` 替代 `[ ]`
## 包管理
- 系统包: `sudo pacman -S --needed --noconfirm <pkgs>`
- AUR 包: `yay -S --needed --noconfirm <pkgs>`
## sh文件规范:
  - 始终保持代码简洁高级
  - 使用函数封装重复代码
  - 文件头部有DOC
  - 步骤有注释
  - 编写完成后,运行测试
## 文件示例
```bash
#!/bin/bash
# file.sh
# DOC

fn() {
    local func="${funcstack[1]}"
    local var=${1:-}
    # 1.
    # 2.
    cat << EOF
执行函数: $func
参数: $var
EOF
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && fn "$@"
```
