# display_rate.zsh — 设置显示器刷新率
# DOC:
#   1. setup_display_env: 安装 kscreen → 检测 Wayland/DBUS 环境变量
#   2. display_rate_list: 调用 kscreen-doctor -o 列出所有输出及可用模式
#   3. display_rate_set: 解析 Modes 行 → 匹配目标刷新率 → kscreen-doctor 设置
# 用法:
#   display_rate.sh -l              # 列出模式
#   display_rate.sh 输出ID 刷新率   # 设置刷新率

# 1. 显示环境准备：安装 kscreen，检测 Wayland/DBUS
setup_display_env() {
    sudo pacman -S --needed --noconfirm kscreen

    local uid
    uid=$(id -u)

    # 1a. 自动检测 Wayland socket
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        local wl_sock
        wl_sock=$(find /run/user/"$uid" -maxdepth 1 -name 'wayland-*' -print -quit 2>/dev/null)
        [[ -n "$wl_sock" ]] && export WAYLAND_DISPLAY=$(basename "$wl_sock")
    fi

    # 1b. 自动检测 DBUS socket
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        local dbus_sock="/run/user/$uid/bus"
        [[ -S "$dbus_sock" ]] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_sock"
    fi
}

# 2. 列出所有输出和可用模式
display_rate_list() {
    setup_display_env
    kscreen-doctor -o
}

# 3. 设置指定输出的目标刷新率
display_rate_set() {
    setup_display_env

    local output_id="$1"
    local target_rate="${2:-60}"
    local matched=0

    # 3a. 解析 kscreen-doctor 输出，查找匹配模式
    while IFS= read -r line; do
        if [[ "$line" =~ Modes: ]]; then
            for entry in $line; do
                if [[ "$entry" =~ ^([0-9]+):.+@([0-9]+) ]]; then
                    local mid="${BASH_REMATCH[1]}"
                    local mrate="${BASH_REMATCH[2]}"
                    # 3b. 找到目标刷新率模式并设置
                    if [[ "$mrate" == "$target_rate" ]]; then
                        kscreen-doctor "output.${output_id}.mode.${mid}" && {
                            echo "已设置 output $output_id 刷新率为 ${target_rate}Hz"
                            matched=1
                            break 2
                        }
                    fi
                fi
            done
        fi
    done < <(kscreen-doctor -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

    # 3c. 未找到匹配模式时提示
    if [[ "$matched" -eq 0 ]]; then
        echo "未找到 ${target_rate}Hz 模式"
    fi
}

