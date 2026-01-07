#!/bin/bash
#--> Configure yay --> 配置 yay
yay_conf() {
    local dir="$HOME/.config/yay"
    mkdir -p "$dir"
    # Create yay config.json with optimized settings
    tee "$dir/config.json" > /dev/null << 'EOF'
{
    "editor": "nano",
    "pacmanbin": "pacman",
    "pacmanconf": "/etc/pacman.conf",
    "answerclean": "All",
    "removemake": "ask",
    "maxconcurrentdownloads": 16,
    "cleanAfter": false,
    "batchinstall": true,
    "DevelCheckUpdate": false
}
EOF
    echo "yay config.json created successfully." # 配置文件创建成功
}
