#!/usr/bin/env bash
set -euo pipefail
source_shrc() {
    local dev="${1:-/dev/sda1}"
    local rc_file="${2:-$HOME/.zshrc}"
    local tag="# add by source_shrc"
    grep -qF "$tag" "$rc_file" 2>/dev/null && { echo "already sourced in $rc_file"; return 0; }
    {
        echo ""
        echo "$tag"
        echo 'mnt=$(findmnt -n -o TARGET '"$dev"' 2>/dev/null)'
        echo 'if [[ -n "$mnt" && -d "${mnt}/.manjaro/scripts/.zsh" ]]; then'
        echo '    for f in "${mnt}/.manjaro/scripts/.zsh/"*.zsh(N); do'
        echo '        source "$f"'
        echo '    done'
        echo 'fi'
    } >> "$rc_file"
    echo "done"
}
source_shrc "$@"
