# ssh_config.zsh — 生成/复制 SSH 密钥
# DOC:
#   1. 备份现有 ~/.ssh → ~/.ssh.bak
#   2. 如果脚本目录下有 .ssh/ 则创建软链接
#   3. 否则用 ed25519 生成新密钥
#   4. 打印公钥
# 用法: ssh_config [email] [ssh_dir]
# 默认: email=19157521820@163.com, ssh_dir=.ssh (相对于脚本目录)

ssh_config() {
    local email="${1:-19157521820@163.com}"
    local ssh_dir="${2:-.ssh}"
    local home_ssh="$HOME/.ssh"

    # 1. 备份现有 ~/.ssh
    if [[ -d "$home_ssh" ]]; then
        local bak="$HOME/.ssh.bak"
        [[ -d "$bak" ]] && rm -rf "$bak"
        mv "$home_ssh" "$bak"
        echo "已备份 $home_ssh → $bak"
    fi

    local src_dir
    src_dir="${funcfiletrace[1]:h}/$ssh_dir"

    # 2. 从脚本目录创建软链接，或生成新密钥
    if [[ -d "$src_dir" ]]; then
        chmod 700 "$src_dir"
        find "$src_dir" -name 'id_*' -exec chmod 600 {} +
        find "$src_dir" -name '*.pub' -exec chmod 644 {} +
        backup_sf "$src_dir" "$home_ssh"
    else
        mkdir -p "$home_ssh"
        ssh-keygen -t ed25519 -C "$email" -f "$home_ssh/id_ed25519" -N ""
        chmod 700 "$home_ssh"
        chmod 600 "$home_ssh/id_ed25519"
        chmod 644 "$home_ssh/id_ed25519.pub"
    fi

    # 3. 输出公钥
    cat "$home_ssh/id_ed25519.pub"
}
