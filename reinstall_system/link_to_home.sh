#!/usr/bin/env bash
set -euo pipefail

link_to_home() {
    local src_dir="${1:-/data/.home}"
    
    # 检查源目录
    [[ ! -d "${src_dir}" ]] && { echo "错误: 源目录 ${src_dir} 不存在" >&2; return 1; }
    
    # 遍历源目录
    shopt -s nullglob dotglob
    for item in "${src_dir}"/*; do
        local name=$(basename "${item}")
        [[ "${name}" == '.' || "${name}" == '..' ]] && continue
        
        local target="${HOME}/${name}"
        
        # 如果目标存在且不是指向源的链接,则备份
        if [[ -e "${target}" && $(readlink -f "${target}") != $(readlink -f "${item}") ]]; then
            local backup="${target}.backup.$(date +%s)"
            mv "${target}" "${backup}"
            echo "已备份: ${target} -> ${backup}"
        fi
        
        # 创建软链接
        ln -sf "${item}" "${HOME}/"
        echo "已链接: ${item} -> ${target}"
    done
    shopt -u nullglob dotglob
}

link_to_home "$@"
