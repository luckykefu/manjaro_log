#!/usr/bin/env bash
# install_cli_tools.sh — 通过 pacman 安装 Rust 编写的 CLI 工具
# 用法:
#   install_cli_tools.sh              # 安装默认列表
#   install_cli_tools.sh bat fd rg    # 安装指定工具
# 默认: bat fd ripgrep eza zoxide git-delta procs dust bottom

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../reinstall_system/lib/packages.sh"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_rust_tools "$@"
fi
