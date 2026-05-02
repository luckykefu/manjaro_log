#!/usr/bin/env bash
set -euo pipefail

set_mirror() {
    # 设置 pacman 镜像源，备份原配置并刷新软件包数据库
    # $1: url (可选, 默认清华镜像)
    local url="${1:-https://mirrors.tuna.tsinghua.edu.cn/manjaro/stable/\$repo/\$arch}"
    
    [[ -f /etc/pacman.d/mirrorlist ]] && sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # 备份原镜像列表
    
    sudo tee /etc/pacman.d/mirrorlist <<EOF
# China mirrors tsinghua
Server = ${url}
EOF
    
    echo "镜像源已设置为: $url"
    
    sudo pacman -Syy  # 刷新软件包数据库
}

set_mirror "$@"
