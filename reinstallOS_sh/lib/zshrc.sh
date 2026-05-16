zshrc() {
    local block_begin="# add by source_shrc" block_end="# end by source_shrc" rc_file="${1:-$HOME/.zshrc}" tmp=$(mktemp)
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local zsh_dir="$SCRIPT_DIR/.zsh"
    awk -v begin="$block_begin" -v end="$block_end" '$0 ~ begin { skip=1 } skip && $0 ~ end { skip=0; next } skip { next } { print }' "${rc_file}" 2>/dev/null > "$tmp" || true
    cat >> "$tmp" << ZSHEOF

$block_begin
mnt="$zsh_dir"
[[ -d "\$mnt" ]] && while IFS= read -r -d '' f; do source "\$f"; done < <(find "\$mnt" -type f -name '*.zsh' -print0)
$block_end
ZSHEOF
    cp "$tmp" "$rc_file" && rm -f "$tmp" && echo "zshrc configured at $rc_file"
}
