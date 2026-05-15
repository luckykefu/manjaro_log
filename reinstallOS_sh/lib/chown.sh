chown_dir() {
    local dir="${1:-/data}"
    local user="${SUDO_USER:-${USER:-$(whoami)}}"
    echo "chown $dir to $user"
    sudo chown -R "$user:$user" $dir
    echo "$dir chowned to $user"
}
