# Shell 编码规范

## 基础规范

- Shebang: `#!/usr/bin/env bash`
- 开头: `set -euo pipefail`
- 变量: `"${VAR}"` 加引号
- 条件: `[[ ]]` 替代 `[ ]`
- 函数: < 30 行，单一职责

## 可靠性

- 检查命令: `command -v cmd >/dev/null 2>&1`
- 检查文件: `[[ -f file ]]` / `[[ -d dir ]]`
- 错误处理: `|| exit 1` 或 `set -e`
- 清理资源: `trap cleanup EXIT`

## 模板

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly CONST="value"

main() {
    [[ $# -lt 1 ]] && { echo "用法: $0 <arg>" >&2; exit 1; }
    echo "处理: $1"
}

trap 'echo "清理..."' EXIT
main "$@"
```
