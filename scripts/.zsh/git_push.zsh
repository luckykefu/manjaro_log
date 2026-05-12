auto_push() {
    local msg="${1:?usage: auto_push <commit message>}"
    git add .
    git commit -m "${msg}"
    git push
}
