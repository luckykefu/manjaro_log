# auto_start.zsh — 配置开机自启应用
# DOC:
#   1. 确定自启应用列表（默认: cryptomator, clash-verge, keepassxc）
#   2. 遍历：查找可执行路径 → 复制或生成 .desktop → 设置 644 权限
# 用法: auto_start [app1 app2 ...]
# 默认: cryptomator clash-verge keepassxc

auto_start() {
    local -a bins=()
    if [[ $# -eq 0 ]]; then
        bins=(cryptomator clash-verge keepassxc)
    else
        bins=("$@")
    fi

    mkdir -p "${HOME}/.config/autostart"

    # 1. 为每个应用创建 .desktop 自启条目
    for bin in "${bins[@]}"; do
        # 1a. 检查可执行文件是否存在
        local path target
        path=$(command -v "$bin") || { echo "skip: $bin not found"; continue; }
        target="${HOME}/.config/autostart/${bin}.desktop"

        # 1b. 优先复制系统 .desktop，否则手动生成
        if [[ -f "/usr/share/applications/${bin}.desktop" ]]; then
            cp "/usr/share/applications/${bin}.desktop" "$target"
        else
            cat > "$target" << EOF
[Desktop Entry]
Type=Application
Name=${bin}
Exec=${path}
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
        fi
        chmod 644 "$target"
        echo "autostart enabled: $bin"
    done
}

