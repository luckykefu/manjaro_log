git_push() {
    local func="${funcstack[1]}"
    [[ -z "${1:-}" ]] && { echo "usage: ${func} <commit message>" >&2; return 1; }
    local msg="$1"
    git add . && git commit -m "${msg}" && git push
}
