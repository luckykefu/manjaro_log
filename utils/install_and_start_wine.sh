#!/bin/bash
#--> Install app to Wine with custom winetricks --> 使用自定义 winetricks 将应用安装到 Wine
install_to_wine() {
    local exe_name="$1"
    shift
    local wineprefix="$HOME/.wine/$exe_name"
    
    WINEPREFIX="$wineprefix"
    
    #--> Create prefix and install dependencies --> 创建前缀并安装依赖
    if [[ ! -d "$wineprefix" ]]; then
        WINEPREFIX="$wineprefix" winetricks cjkfonts "$@"
        WINEPREFIX="$wineprefix" wine "$HOME/Downloads/exe/${exe_name}.exe"
    else
        WINEPREFIX="$wineprefix" winetricks "$@"
    fi
    echo "Wine prefix created: $wineprefix"
}

#--> Start Wine executable --> 启动 Wine 可执行文件
start_wine_exe() {
    local exe_name="$1"
    local exe_path="$2"
    local wineprefix="$HOME/.wine/$exe_name"
    WINEPREFIX="$wineprefix" wine "$exe_path"
}

#--> Main execution --> 主执行
if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    case "$1" in
        --install)
            shift
            install_to_wine "$@"
            ;;
        --start)
            shift
            start_wine_exe "$@"
            ;;
        *)
            echo "Usage / 用法: $0 --install <app_name> [winetricks...]"
            echo "       $0 --start <app_name> <exe_path>"
            exit 1
            ;;
    esac
fi