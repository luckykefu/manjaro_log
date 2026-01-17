#!/bin/bash
# ============================================================================
# Script: setup_autostart.sh
# Description: Create autostart desktop entries for specified applications
# Logic: For each application, finds executable path and creates .desktop file
#        in ~/.config/autostart with proper Desktop Entry format
# ============================================================================
# 脚本: setup_autostart.sh
# 描述: 为指定应用程序创建自动启动桌面条目
# 逻辑: 对每个应用程序，查找可执行文件路径并在 ~/.config/autostart 中创建
#        符合 Desktop Entry 格式的 .desktop 文件
# ============================================================================

#--> Setup autostart function --> 设置自动启动函数
autostart_conf() {
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    for app in "$@"; do
        local exec_path=$(which "$app" 2>/dev/null)
        [[ -z "$exec_path" ]] && echo "Failed to find $app" && continue
        
        cat > "$autostart_dir/$app.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$app
Exec=$exec_path
Icon=$app
Comment=Auto-start $app
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
EOF
        echo "Created autostart file for $app"
    done
}
