#!/bin/bash
# 安装 WhiteSur KDE 主题/图标/光标
# 入参: KDE_CFG_PROJECT_ROOT, KDE_CFG_PROXY, KDE_CFG_WHITESUR_*_REPO

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/config.sh"

ensure_repo() {
    local name="$1" local_path="$2" remote_url="$3"
    [[ -d "$local_path" ]] && { echo "[INFO] $name 已存在: $local_path"; return 0; }
    echo "[INFO] 克隆 $name ..."

    ALL_PROXY="$KDE_CFG_PROXY" git clone --depth 1 "$remote_url" "$local_path" 2>/dev/null && return 0

    echo "[WARN] 代理克隆失败,尝试直连..."
    git clone --depth 1 "$remote_url" "$local_path" && return 0

    echo "[ERROR] $name 克隆失败"
    return 1
}

run_install() {
    local name="$1" local_path="$2"
    [[ ! -d "$local_path" ]] && { echo "[ERROR] $name 本地仓库不存在: $local_path"; return 1; }
    echo "[INFO] 安装 $name ..."
    (cd "$local_path" && bash ./install.sh) || { echo "[ERROR] $name 安装失败"; return 1; }
    echo "[INFO] $name 安装完成"
}

install_whitesur_theme() {
    local local_repo="$KDE_CFG_PROJECT_ROOT/WhiteSur-kde"
    ensure_repo "WhiteSur KDE 主题" "$local_repo" "$KDE_CFG_WHITESUR_KDE_REPO" || return 1
    local target="$HOME/.local/share/plasma/look-and-feel/WhiteSur"
    [[ -d "$target" ]] && { echo "[INFO] WhiteSur KDE 主题已安装,跳过"; return 0; }
    run_install "WhiteSur KDE 主题" "$local_repo"
}

install_whitesur_icons() {
    local local_repo="$KDE_CFG_PROJECT_ROOT/WhiteSur-icon-theme"
    ensure_repo "WhiteSur 图标" "$local_repo" "$KDE_CFG_WHITESUR_ICON_REPO" || return 1
    local target="$HOME/.local/share/icons/WhiteSur"
    [[ -d "$target" ]] && { echo "[INFO] WhiteSur 图标已安装,跳过"; return 0; }
    run_install "WhiteSur 图标" "$local_repo"
}

install_whitesur_cursors() {
    local local_repo="$KDE_CFG_PROJECT_ROOT/WhiteSur-cursors"
    ensure_repo "WhiteSur 光标" "$local_repo" "$KDE_CFG_WHITESUR_CURSORS_REPO" || return 1
    local target="$HOME/.local/share/icons/WhiteSur-cursors"
    [[ -d "$target" ]] && { echo "[INFO] WhiteSur 光标已安装,跳过"; return 0; }
    run_install "WhiteSur 光标" "$local_repo"
}

install_mac_themes() {
    echo "[INFO] 安装 mac themes ..."
    local ok=0
    install_whitesur_theme || ((ok++))
    install_whitesur_icons || ((ok++))
    install_whitesur_cursors || ((ok++))
    [[ "$ok" -gt 0 ]] && { echo "[WARN] mac themes 有 $ok 项安装失败"; return 1; }
    echo "[INFO] mac themes 全部安装完成"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && {
    load_config
    install_mac_themes
}
