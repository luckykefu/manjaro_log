pacman_cfg() {
    local pacman_conf="/etc/pacman.conf" block_begin="# add by pacman_cfg" block_end="# end add by pacman_cfg"
    local tmp; tmp=$(mktemp)
    awk -v begin="$block_begin" -v end="$block_end" '$0 ~ begin { skip=1 } skip && $0 ~ end { skip=0; next } skip { next } { print }' "$pacman_conf" > "$tmp"
    cat >> "$tmp" << 'AWKEOF'

# add by pacman_cfg
[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
# end add by pacman_cfg
AWKEOF
    sudo cp "$tmp" "$pacman_conf" && rm -f "$tmp" && echo "archlinuxcn repo configured in $pacman_conf"
    sudo pacman -Syy --noconfirm && sudo pacman -S --noconfirm archlinuxcn-keyring && echo "pacman-cfg done"
}
