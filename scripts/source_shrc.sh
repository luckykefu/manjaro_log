#!/usr/bin/env bash
set -euo pipefail
source_shrc() {
    local dir="${1:-.zsh}"
    local rc_file="${2:-$HOME/.zshrc}"
    cd "$(dirname "$0")"
    dir="$(CDPATH= cd "$dir" && pwd)"
    while IFS= read -r -d '' f; do
        line="source \"$f\""
        if ! grep -Fxq "$line" "$rc_file" 2>/dev/null; then
            echo "$line" >> "$rc_file"
            echo "添加: $line"
        fi
    done < <(find "$dir" -name '*.zsh' -type f -print0)
}
source_shrc "$@"
