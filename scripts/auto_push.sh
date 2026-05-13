#!/usr/bin/env bash

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "${COMMON_DIR}/common.sh"

auto_push() {
    ensure_cmd git
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local dirs=("$script_dir/.." "$script_dir/../../.cryptomator")

    for dir in "${dirs[@]}"; do
        [[ -d "$dir/.git" ]] || continue
        cd "$dir"
        git add -A
        git diff --cached --quiet || git commit -m "$(date '+%Y-%m-%d')"
        git push
    done
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && auto_push