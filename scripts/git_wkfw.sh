#!/bin/bash
# 用法: bash git_wkfw.sh "commit message"

set -euo pipefail

MSG="${1:?'usage: bash git_wkfw.sh \"commit message\"'}"

git add .
git commit -m "$MSG"
git push
