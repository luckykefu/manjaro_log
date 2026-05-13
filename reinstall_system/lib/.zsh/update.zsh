# .zsh/update.zsh — 全系统更新（pacman + yay）
update() {
    sudo pacman -Syyu --noconfirm
    yay -Syyu --noconfirm
}
