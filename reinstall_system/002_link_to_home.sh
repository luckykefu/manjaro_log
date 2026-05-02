#!/usr/bin/env bash
set -euo pipefail

link_to_home() {
    # 将 src_dir 下所有文件软链接到 HOME，已存在文件先备份
    # $1: src_dir (可选, 默认 /data/.home)
    local src_dir="${1:-/data/.home}"  # 源目录，默认 /data/.home
    
    [[ ! -d "${src_dir}" ]] && { echo "错误: 源目录 ${src_dir} 不存在" >&2; return 1; }  # 源目录不存在则退出
    
    shopt -s nullglob dotglob  # 匹配隐藏文件和空目录
    for item in "${src_dir}"/*; do
        local name=$(basename "${item}")
        [[ "${name}" == '.' || "${name}" == '..' ]] && continue  # 跳过 . ..
        
        local target="${HOME}/${name}"
        
        # 目标已存在且不是指向源的链接，则备份
        if [[ -e "${target}" && $(readlink -f "${target}") != $(readlink -f "${item}") ]]; then
            local backup="${target}.backup.$(date +%s)"
            mv "${target}" "${backup}"  # 加时间戳避免备份名冲突
            echo "已备份: ${target} -> ${backup}"
        fi
        
        ln -sf "${item}" "${HOME}/"  # 创建软链接
        echo "已链接: ${item} -> ${target}"
    done
    shopt -u nullglob dotglob  # 恢复 shopt 默认设置
}

link_to_home "$@"
