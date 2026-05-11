#!/bin/sh

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
source_shrc() {
    dir="${1:-../zsh}"
    rc_file="${2:-$HOME/.zshrc}"

    if [ -z "$dir" ] || [ -z "$rc_file" ]; then
        echo "用法: source_shrc <dir> <rc_file>"
        return 1
    fi

    cd "$SCRIPT_DIR" || return 1
    dir="$(CDPATH= cd "$dir" && pwd)" || return 1

    for f in "$dir"/*.zsh; do
        [ -f "$f" ] || continue
        line="source \"$f\""
        if ! grep -Fxq "$line" "$rc_file" 2>/dev/null; then
            echo "$line" >> "$rc_file"
            echo "添加: $line"
        fi
    done
}
