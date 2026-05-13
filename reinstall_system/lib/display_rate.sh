#!/usr/bin/env bash
# display_rate.sh — 设置显示器刷新率
# 用法:
#   display_rate.sh -l             # 列出所有输出及可用模式
#   display_rate.sh 输出ID 刷新率  # 设置指定输出的刷新率

setup_display_env() {
    sudo pacman -S --needed --noconfirm kscreen

    local uid
    uid=$(id -u)

    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        local wl_sock
        wl_sock=$(find /run/user/"$uid" -maxdepth 1 -name 'wayland-*' -print -quit 2>/dev/null)
        [[ -n "$wl_sock" ]] && export WAYLAND_DISPLAY=$(basename "$wl_sock")
    fi

    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        local dbus_sock="/run/user/$uid/bus"
        [[ -S "$dbus_sock" ]] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_sock"
    fi
}

display_rate_list() {
    setup_display_env
    kscreen-doctor -o
}

display_rate_set() {
    setup_display_env

    local output_id="$1"
    local target_rate="${2:-60}"
    local matched=0

    while IFS= read -r line; do
        if [[ "$line" =~ Modes: ]]; then
            for entry in $line; do
                if [[ "$entry" =~ ^([0-9]+):.+@([0-9]+) ]]; then
                    local mid="${BASH_REMATCH[1]}"
                    local mrate="${BASH_REMATCH[2]}"
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

    if [[ "$matched" -eq 0 ]]; then
        echo "未找到 ${target_rate}Hz 模式"
    fi
}

main() {
    case "${1:-}" in
        -l|--list)      display_rate_list ;;
        -h|--help)      head -5 "$0" | grep '^#' | sed 's/^# //' ;;
        *)
            if [[ $# -eq 2 ]]; then
                display_rate_set "$1" "$2"
            else
                echo "用法: display_rate.sh [-l|输出ID 刷新率]" >&2
                return 1
            fi
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
