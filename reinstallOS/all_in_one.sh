create_snapshot() {
    local name="${1:?snapshot name required}"
    local dir="/.snapshots/$name"

    sudo mkdir -p /.snapshots || return 1
    [[ -d "$dir" ]] && { echo "exists: $dir"; return 2; }

    sudo btrfs subvolume snapshot / "$dir"
}

sudo_nopassword() {
    local sudoers_file="/etc/sudoers.d/${USER}_nopassword"

    sudo test -f "$sudoers_file" && { echo "exists: $sudoers_file"; return 2; }

    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null \
        && sudo chmod 0440 "$sudoers_file" \
        && sudo visudo -c &>/dev/null \
        || { sudo rm -f "$sudoers_file"; echo "failed, rolled back" >&2; return 1; }
}

pacman_cfg() {
    local conf="/etc/pacman.conf"
    local mark="# pacman_cfg"

    sudo sed -i "/${mark}/,/${mark}/d" "$conf" \
        && sudo tee -a "$conf" > /dev/null << EOF
${mark}
[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
${mark}
EOF\
        && sudo pacman -Sy --noconfirm \
        && sudo pacman -S --noconfirm --needed archlinuxcn-keyring \
        || { echo "${mark} failed" >&2; return 1; }

    echo "${mark} done"
}
git_cfg() {
    local name="${1:-kefu}"
    local email="${2:-19157521820@163.com}"

    git config --global \
        user.name "$name" \
        user.email "$email" \
        init.defaultBranch main \
        credential.helper libsecret \
        || { echo "git_cfg failed" >&2; return 1; }

    echo "git_cfg done"
}
gpg_cfg() {
    local name="${1:-kefu}" email="${2:-19157521820@163.com}" passphrase="${3:-lkf.Gpg.mima3}"

    gpg --list-keys "$email" &>/dev/null && { echo "gpg_cfg exists"; return 2; }

    gpgconf --kill gpg-agent 2>/dev/null || true

    gpg --batch --gen-key <(cat << EOF
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: $name
Name-Email: $email
Expire-Date: 0
Passphrase: $passphrase
%commit
EOF
    ) || { echo "gpg_cfg failed" >&2; return 1; }

    echo "gpg_cfg done"
}

ssh_cfg() {
    local email="${1:-kefu1820@gmail.com}"
    local src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/.ssh"
    local dst="$HOME/.ssh"

    [[ ! -d "$src" ]] && {
        mkdir -p "$src"
        local args=(-t ed25519 -f "$src/id_ed25519" -N "")
        [[ -n "$email" ]] && args+=(-C "$email")
        ssh-keygen "${args[@]}"
    }

    [[ -e "$dst" ]] && rm -rf "$dst"
    ln -sf "$src" "$dst" || { echo "ssh_cfg failed" >&2; return 1; }

    echo "ssh_cfg done"
}
zshrc_cfg() {
    local rc_file="${1:-$HOME/.zshrc}"
    local zsh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/.zsh"
    local mark="# zshrc_cfg"

    sed -i "/^${mark}$/,/^${mark}$/d" "$rc_file" 2>/dev/null || true

    cat >> "$rc_file" << EOF
${mark}
mnt="$zsh_dir"
[[ -d "\$mnt" ]] && while IFS= read -r -d '' f; do source "\$f"; done < <(find "\$mnt" -type f -name '*.zsh' -print0)
${mark}
EOF

    echo "zshrc_cfg done"
}
autostart() {
    mkdir -p "$HOME/.config/autostart"
    for app in "$@"; do
        local found=$(find /usr/share/applications -iname "*${app}*.desktop" -print -quit 2>/dev/null)
        [[ -n "$found" ]] && cp -f "$found" "$HOME/.config/autostart/$(basename "$found")" \
            && echo "autostart: $app" \
            || echo "autostart: $app not found" >&2
    done
}
step=000_org && echo "$step"
create_snapshot "$step"

step=000_sudo_nopassword && echo "$step"
sudo_nopassword
create_snapshot "$step"

step=001_pacman_cfg && echo "$step"
sudo pacman-mirrors -c China
pacman_cfg
create_snapshot "$step"

step=002_base_cfg && echo "$step"
git_cfg
gpg_cfg
ssh_cfg
zshrc_cfg
sudo systemctl enable fstrim.timer
tz=UTC && sudo timedatectl set-timezone "$tz" && sudo timedatectl set-ntp true && echo "timezone Done"
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/theme.sh"
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/general.sh"
create_snapshot "$step"

step=003_update_linux70 && echo "$step"
sudo pacman -Syyu --noconfirm
sudo pacman -S --needed --noconfirm linux70 linux70-headers && sudo grub-set-default "0>"
create_snapshot "$step"

step=004_app_cfg && echo "$step"
base_pkg=(base-devel yay keepassxc jq yq shellcheck telegram-desktop tailscale)
fonts_pkg=(inter-font adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation wqy-microhei wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts ttf-fira-code ttf-roboto)
rust_pkg=(rust rust-analyzer clang lld capnproto redis)
fcitx5_pkg=(fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-pinyin-zhwiki)
sudo pacman -Sy --noconfirm --needed "${base_pkg[@]}" "${fonts_pkg[@]}" "${rust_pkg[@]}" "${fcitx5_pkg[@]}"

yay_pkg=(cryptomator-bin google-chrome)
yay -Sy --noconfirm --needed "${yay_pkg[@]}"
autostart cryptomator keepassxc

sudo systemctl enable --now redis
sudo systemctl enable --now tailscaled
sudo systemctl enable --now sshd
kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.fcitx.Fcitx5.desktop

curl -fsSL https://opencode.ai/install | sh
curl -f https://zed.dev/install.sh | sh
# sudo tailscale up
create_snapshot "$step"
reboot
