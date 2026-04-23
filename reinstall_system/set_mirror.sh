#!/usr/bin/env bash
set -euo pipefail

set_mirror() {
    local url="${1:-https://mirrors.tuna.tsinghua.edu.cn/manjaro/stable/\$repo/\$arch}"
    
    # 备份原镜像列表
    [[ -f /etc/pacman.d/mirrorlist ]] && sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    
    # 写入新镜像配置
    sudo tee /etc/pacman.d/mirrorlist <<EOF
# China mirrors tsinghua
Server = $url
EOF
    
    echo "镜像源已设置为: $url"
    
    # 刷新软件包数据库
    sudo pacman -Syy
}

set_mirror "$@"
