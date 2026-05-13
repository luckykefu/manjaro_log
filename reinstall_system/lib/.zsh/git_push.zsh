# git_push.zsh — Git 快速提交推送
# DOC:
#   1. 校验提交信息参数
#   2. git add . → git commit → git push
# 用法: git_push "commit message"

git_push() {
    local func="${funcstack[1]}"
    [[ -z "${1:-}" ]] && return 1
    local msg="$1"
    # 1. 三段式：add → commit → push
    git add . && git commit -m "${msg}" && git push
}
