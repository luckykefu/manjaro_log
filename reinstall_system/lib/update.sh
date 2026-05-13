#!/usr/bin/env bash
# update.sh — 将函数定义委托到 .zsh/update.zsh
# 用法: update

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${SCRIPT_DIR}/.zsh/update.zsh" ]]; then
    echo "Error: ${SCRIPT_DIR}/.zsh/update.zsh not found" >&2
    return 1 2>/dev/null || exit 1
fi

source "${SCRIPT_DIR}/.zsh/update.zsh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    update
fi
