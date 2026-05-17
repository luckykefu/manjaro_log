zshrc() {
    local block_begin="# add by source_shrc" block_end="# end by source_shrc" rc_file="${1:-$HOME/.zshrc}"
    local zsh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.zsh"
    sed -i "/^$block_begin/,/^$block_end/d" "$rc_file" 2>/dev/null || true
    cat >> "$rc_file" << EOF

$block_begin
mnt="$zsh_dir"
[[ -d "\$mnt" ]] && while IFS= read -r -d '' f; do source "\$f"; done < <(find "\$mnt" -type f -name '*.zsh' -print0)
$block_end
EOF
    echo "zshrc configured at $rc_file"
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]] ;then
    zshrc
fi
