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
if [[ "${BASH_SOURCE[0]}" == "$0" ]] ;then
    ssh_keygen "$@"
fi
