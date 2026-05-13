# update.zsh — 全系统更新函数
# DOC:
#   1. pacman 系统包全量更新
#   2. yay AUR 包全量更新
# 用法: update

update() {
    # 1. 系统包更新
    sudo pacman -Syyu --noconfirm
    # 2. AUR 包更新
    yay -Syyu --noconfirm
}
