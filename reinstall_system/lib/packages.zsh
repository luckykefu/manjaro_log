# packages.zsh — 统一包安装入口，按类别安装系统/AUR 包
# DOC:
#   pacman_install:     执行 sudo pacman -S（依赖 ensure_cmd）
#   yay_install:        执行 yay -S --needed --noconfirm（AUR 包）
#   install_fcitx5_pkgs:安装 Fcitx5 输入法包（委托 pacman_install）
#   install_rust_tools: 安装 Rust CLI 工具（委托 pacman_install）
# 用法:
#   install_rust_tools [pkg...]     # 默认: bat, fd, ripgrep...
# 示例:
#   install_rust_tools bat fd rg

# 系统包安装（依赖 ensure_cmd）
pacman_install() {
    ensure_cmd pacman
}

# AUR 包安装
yay_install() {
    ensure_cmd yay
    yay -S --needed --noconfirm "$@"
}

# Fcitx5 输入法包安装
install_fcitx5_pkgs() {
    pacman_install
}

# Rust CLI 工具安装
install_rust_tools() {
    local tools=()
    [[ $# -gt 0 ]] && tools=("$@")

    echo "=== Installing Rust CLI tools via pacman ==="
    pacman_install "${tools[@]}"
    echo "=== Done ==="
}

