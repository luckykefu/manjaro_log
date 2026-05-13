#!/usr/bin/env bash
set -euo pipefail

source_shrc() {
    local rc_file="${1:-$HOME/.zshrc}"
    local tag="# add by source_shrc"

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local zsh_dir="${script_dir}/.zsh"

    mkdir -p "$zsh_dir"

    grep -qF "$tag" "$rc_file" 2>/dev/null && { info "source_shrc 已存在 $rc_file"; return 0; }
    {
        echo ""
        echo "$tag"
        echo "script_dir=\"\${0:A:h}\""
        echo "mnt=\"\${script_dir}/.zsh\""
        echo 'if [[ -d "$mnt" ]]; then'
        echo '    for f in "${mnt}/"*.zsh(N); do'
        echo '        source "$f"'
        echo '    done'
        echo 'fi'
    } >> "$rc_file"
    info "source_shrc 已写入 $rc_file"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && source_shrc "$@"
