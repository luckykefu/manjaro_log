ssh_keygen() {
    local email="${1:-'kefu1820@gmail.com'}"
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ssh_src="$SCRIPT_DIR/.ssh"
    local ssh_dst="$HOME/.ssh"
    if [[ -d "$ssh_src" ]];then
       rm -rf "$ssh_dst" && ln -sf "$ssh_src" "$ssh_dst"
    else
        mkdir -p "$ssh_src"
        local args=(-t ed25519 -f "$ssh_src/id_ed25519" -N "")
        [[ -n "$email" ]] && args+=(-C "$email")
        ssh-keygen "${args[@]}" && echo "SSH key generated at $ssh_src/id_ed25519"
        rm -rf "$ssh_dst" && ln -sf "$ssh_src" "$ssh_dst"
    fi
}
