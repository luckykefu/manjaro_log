#!/usr/bin/env bash
set -euo pipefail

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

git_cfg(){
    local name="${1:-kefu}"
    local email="${2:-19157521820@163.com}"
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    git config --global credential.helper libsecret
    echo "git configured"

}

gen_gpg(){
    local name="${1:-kefu}" email="${2:-19157521820@163.com}" passphrase="${3:-lkf.Gpg.mima3}"
    gpg --list-keys "$email" &>/dev/null || {
        local batch_file=$(mktemp)
        cat > "$batch_file" << BATCHEOF
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: $name
Name-Email: $email
Expire-Date: 0
Passphrase: $passphrase
%commit
BATCHEOF
        gpgconf --kill gpg-agent 2>/dev/null || true
        gpg --batch --gen-key "$batch_file"
        rm -f "$batch_file"
    }
    echo "GPG done"
}


linker(){
    local src=$1
    local dst=$2
    [[ ! -d "$src" ]] && {
        mkdir -p "$src"
        local args=(-t ed25519 -f "$src/id_ed25519" -N "")
        [[ -n "$email" ]] && args+=(-C "$email")
        ssh-keygen "${args[@]}"
    }
    rm -rf "$dst" && ln -sf "$src" "$dst"
}
ssh_keygen() {
    local email="${1:-'kefu1820@gmail.com'}"
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local src="$SCRIPT_DIR/.ssh"
    local dst="$HOME/.ssh"
    linker "$src" "$dst"
}
zshrc() {
    local block_begin="# add by source_shrc" block_end="# end by source_shrc" rc_file="${1:-$HOME/.zshrc}"
    local zsh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.zsh"
    sed -i "/^$block_begin/,/^$block_end/d" "$rc_file" 2>/dev/null || true
    cat >> "$rc_file" << EOF

$block_begin
mnt="$zsh_dir"
[[ -d "\$mnt" ]] && while IFS= read -r -d '' f; do source "\$f"; done < <(find "\$mnt" -type f -name '*.zsh' -print0)
$block_end
EOF
    echo "zshrc configured at $rc_file"
}

pacman_cfg
git_cfg
gen_gpg
ssh_keygen
zshrc
base_pkg=(base-devel yay keepassxc jq yq shellcheck telegram-desktop)
sudo pacman -S --noconfirm --needed "${base_pkg[@]}"
fonts_pkg=(inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation wqy-microhei wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts ttf-fira-code ttf-roboto)
sudo pacman -S --noconfirm --needed "${fonts_pkg[@]}"
rust_pkg=(rust clang lld capnproto redis)
sudo pacman -S --noconfirm --needed $rust_pkg
sudo systemctl enable --now redis

sudo pacman -S --noconfirm --needed tailscale
sudo systemctl enable --now tailscaled
sudo systemctl enable --now sshd
sudo tailscale up
