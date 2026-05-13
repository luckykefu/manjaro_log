# backup.zsh — 删除目标并创建软链接
# DOC:
#   1. $1=源文件/目录, $2=目标路径
#   2. 若 $2 为目录或链接则删除
#   3. 创建软链接 $1 → $2
# 用法: backup_sf <src> <dst>

backup_sf() {
    local src="$1"
    local dst="$2"

    [[ -z "$src" || -z "$dst" ]] && return 1

    # 1. 删除 $dst（目录或链接）
    [[ -d "$dst" || -L "$dst" ]] && rm -rf "$dst"

    # 2. 创建软链接 $1 → $2（-f 覆盖残余）
    ln -sf "$src" "$dst"
}
