#!/usr/bin/env bash
set -euo pipefail

auto_push() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local DIRS=(
        "$SCRIPT_DIR/.."
        "$SCRIPT_DIR/../../.cryptomator"
    )
    for DIR in "${DIRS[@]}"; do
        if [[ -d "$DIR/.git" ]]; then
            echo "=== 正在处理: $DIR ==="
            cd "$DIR" && git add -A && git diff --cached --quiet || git commit -m "$(date '+%Y-%m-%d')" && git push
        else
            echo "=== 跳过: $DIR (不是 git 仓库或未挂载) ==="
        fi
    done
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && auto_push