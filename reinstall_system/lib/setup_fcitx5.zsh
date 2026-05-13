# setup_fcitx5.zsh — 配置 Fcitx5 输入法
# DOC:
#   1. 加载 packages.sh（包安装函数）
#   2. kwriteconfig6 设置 kwin Wayland 输入法为 fcitx5
#   3. 删除旧 ~/.config/fcitx5
#   4. 复制预设配置到 ~/.config/fcitx5
# 用法: setup_fcitx5

SCRIPT_DIR="${${(%):-%N}:A:h}"
source "${SCRIPT_DIR}/packages.zsh"

setup_fcitx5() {
    # 1. 设置 kwin Wayland 输入法为 fcitx5
    kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop
    # 2. 删除旧配置，创建软链到预设配置
    backup_sf "${SCRIPT_DIR}/fcitx5" "$HOME/.config/fcitx5"
}
