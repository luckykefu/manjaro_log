#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"  # 确保在脚本目录下执行
dir="${1:?usage: ${0##*/} <dir>}"
[[ -d "${dir}" ]] || { echo "error: not a directory: ${dir}" >&2; exit 1; }
find "${dir}" -type f -name '*.sh' -print -exec chmod +x {} \;
