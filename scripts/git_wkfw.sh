#!/usr/bin/env bash
# 用法: git_wkfw.sh "commit message"

set -euo pipefail

git_wkfw() {
    local MSG="${1:?'usage: git_wkfw.sh \"commit message\"'}"
    git add .
    git commit -m "$MSG"
    git push
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && git_wkfw "$@"