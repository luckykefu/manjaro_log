#!/usr/bin/env bash

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "${COMMON_DIR}/common.sh"
# 用法: git_wkfw.sh "commit message"

git_wkfw() {
    ensure_cmd git
    local MSG="${1:?'usage: git_wkfw.sh \"commit message\"'}"
    git add .
    git commit -m "$MSG"
    git push
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && git_wkfw "$@"