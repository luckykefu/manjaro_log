#!/usr/bin/env bash
# common.sh — 通用错误处理工具函数
# 用法: source 本文件后使用 ensure_cmd / rm_or_skip

# 检查命令是否存在，不存在则安装
# 用法: ensure_cmd <command> [package_name]
# 默认 package_name = command
ensure_cmd() {
    local cmd="$1"                                    # 首个参数: 要检查的命令名
    local pkg="${2:-$1}"                              # 第二参数: 包名(缺省=命令名)
    command -v "$cmd" &>/dev/null && return 0          # 命令已存在 → 跳过安装
    echo "$cmd not found, installing $pkg..."          # 打印提示信息
    sudo pacman -Sy --needed --noconfirm "$pkg"        # 静默安装缺失包
}

# 文件/目录存在时删除或跳过，始终返回0（兼容 set -e）
# 用法: rm_or_skip <path> <action>
# action = delete | skip
rm_or_skip() {
    local path="$1"                                   # 首个参数: 待检查路径
    local action="${2:-skip}"                         # 第二参数: 动作(delete/skip)
    [[ -e "$path" ]] || return 0                      # 路径不存在 → 直接返回成功
    if [[ "$action" == "delete" ]]; then              # 动作=delete → 强制删除
        rm -rf "$path"                                # 递归强制删除路径
    fi                                                # skip则什么都不做
}
