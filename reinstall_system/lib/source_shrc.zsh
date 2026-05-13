# source_shrc.zsh — 在 shell rc 文件中注入 .zsh/ 下所有 .zsh 的自动加载
# DOC:
#   1. 确保 .zsh/ 目录存在
#   2. 删除旧的 source_shrc 配置块
#   3. 追加新配置块：find 加载所有 *.zsh
# 用法: source_shrc [rc_file]
# 默认: rc_file=$HOME/.zshrc

source_shrc() {
    local rc_file="${1:-$HOME/.zshrc}"
    local script_dir="${funcfiletrace[1]:h}"

    # 1. 确保 .zsh/ 目录存在
    mkdir -p "${script_dir}/.zsh"

    # 2. 删除旧的 source_shrc 配置块
    sed -i.bak '/^# add by source_shrc$/,/^# end by source_shrc$/d' "$rc_file" 2>/dev/null || true

    # 3. 追加新配置块：递归加载 .zsh/ 下所有 *.zsh
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

