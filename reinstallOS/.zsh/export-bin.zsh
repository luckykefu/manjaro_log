#!/usr/bin/env zsh

# export-bin.zsh — 将脚本目录上级的 .bin/ 加入 PATH
# DOC:
#   PATH 追加 ${script_dir}/../.bin
# 说明: 假设 lib/.zsh/export-bin.zsh → 上级上级 = 项目根 → .bin/

export PATH="${0:A:h}/.bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
