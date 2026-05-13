#!/usr/bin/env bash
# source_shrc.sh
# 在 shell rc 文件中注入 .zsh/ 下所有 .zsh 的自动加载（递归）
# 用法: source_shrc [rc_file]
# 默认: rc_file=$HOME/.zshrc

source_shrc() {
    local rc_file="${1:-$HOME/.zshrc}"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    ensure_cmd sed
    mkdir -p "${script_dir}/.zsh"

    # 删除旧配置块，追加新配置
    sed -i.bak '/^# add by source_shrc$/,/^# end by source_shrc$/d' "$rc_file" 2>/dev/null || true

    cat >> "$rc_file" << EOF2

# add by source_shrc
mnt="${script_dir}/.zsh"
if [[ -d "\$mnt" ]]; then
    while IFS= read -r -d '' f; do
        source "\$f"
    done < <(find "\$mnt" -type f -name '*.zsh' -print0)
fi
# end by source_shrc
EOF2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    source_shrc "$@"
fi
