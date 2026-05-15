sudo_nopassword() {
    local user="${1:-}"; [[ -z "$user" ]] && user="${SUDO_USER:-${USER:-$(whoami)}}"
    [[ -z "$user" ]] && { echo "error: cannot determine current user" >&2; return 1; }
    id "$user" &>/dev/null || { echo "error: user $user not found" >&2; return 1; }
    local sudoers_file="/etc/sudoers.d/$user" tmp; tmp=$(mktemp "/tmp/sudoers_${user}_XXXXXX")
    printf "%s ALL=(ALL) NOPASSWD: ALL\n" "$user" > "$tmp"
    sudo cp "$tmp" "$sudoers_file" && sudo chmod 0440 "$sudoers_file" && rm -f "$tmp" && echo "passwordless sudo configured for $user"
}
