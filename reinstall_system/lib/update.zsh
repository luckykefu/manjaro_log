# update.zsh — 系统更新委托入口
# DOC:
#   1. 检查 .zsh/update.zsh 是否存在
#   2. source 加载 update 函数定义
#   3. 执行 update（pacman + yay 全量更新）
# 用法: update

SCRIPT_DIR="${${(%):-%N}:A:h}"

# 1. 检查依赖文件
if [[ ! -f "${SCRIPT_DIR}/.zsh/update.zsh" ]]; then
    echo "Error: ${SCRIPT_DIR}/.zsh/update.zsh not found" >&2
    return 1 2>/dev/null || exit 1
fi

# 2. 加载 update 函数
source "${SCRIPT_DIR}/.zsh/update.zsh"
