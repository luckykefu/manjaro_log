# shellcheck shell=bash
pacman_cfg() {
    local pacman_conf="/etc/pacman.conf" block_begin="# add by pacman_cfg" block_end="# end add by pacman_cfg"
    sudo sed -i "/^${block_begin}$/,/^${block_end}$/d" "$pacman_conf"
    sudo tee -a "$pacman_conf" > /dev/null << 'EOF'

# add by pacman_cfg
[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
# end add by pacman_cfg
EOF
    echo "archlinuxcn repo configured in $pacman_conf"
    sudo pacman -Syy --noconfirm && sudo pacman -S --noconfirm --needed archlinuxcn-keyring && echo "pacman-cfg done"
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]] ;then
    pacman_cfg "$@"
fi
