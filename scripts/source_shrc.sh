#!/usr/bin/env bash
set -euo pipefail
source_shrc() {
    local rc_file="${1:-$HOME/.zshrc}"
    local tag="# add by source_shrc"
    
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local zsh_dir="${script_dir}/.zsh"
    
    mkdir -p "$zsh_dir"
    
    grep -qF "$tag" "$rc_file" 2>/dev/null && { echo "already sourced in $rc_file"; return 0; }
    {
        echo ""
        echo "$tag"
        echo "mnt=\"${zsh_dir}\""
        echo 'if [[ -d "$mnt" ]]; then'
        echo '    for f in "${mnt}/"*.zsh(N); do'
        echo '        source "$f"'
        echo '    done'
        echo 'fi'
    } >> "$rc_file"
    echo "done"
}
source_shrc "$@"