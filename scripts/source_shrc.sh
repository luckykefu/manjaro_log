#!/usr/bin/env bash
set -euo pipefail
source_shrc() {
    local rc_file="${1:-$HOME/.zshrc}"
    local tag="# add by source_shrc"
    
    # 解析脚本自身路径（支持软链接）
    local self_path="${BASH_SOURCE[0]}"
    local script_path
    script_path="$(cd "$(dirname "${self_path}")" && pwd)"
    local script_dir="${script_path##*/}"  # 只取最后一级目录名
    
    # 构建 .zsh 目录：与脚本同级的 .zsh 文件夹
    local zsh_dir="${script_path}/.zsh"
    
    mkdir -p "${zsh_dir}"
    
    grep -qF "$tag" "$rc_file" 2>/dev/null && { echo "already sourced in $rc_file"; return 0; }
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
    echo "done"
}
[[ "${BASH_SOURCE[0]}" == "$0" ]] && source_shrc "$@"