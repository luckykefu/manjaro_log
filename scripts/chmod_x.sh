#!/usr/bin/env bash
set -euo pipefail

chmod_x() {
    local dir="${1:?usage: chmod_x.sh <dir>}"
    [[ -d "$dir" ]] || { echo "error: not a directory: $dir" >&2; exit 1; }
    find "$dir" -type f -name '*.sh' -print -exec chmod +x {} \;
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && chmod_x "$@"