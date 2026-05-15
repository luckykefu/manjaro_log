git_cfg() {
    local name="${1:-kefu}" email="${2:-19157521820@163.com}"
    local current_name=$(git config --global user.name 2>/dev/null || echo "")
    local current_email=$(git config --global user.email 2>/dev/null || echo "")
    [[ "$current_name" != "$name" ]] && git config --global user.name "$name" && echo "git user.name set to $name"
    [[ "$current_email" != "$email" ]] && git config --global user.email "$email" && echo "git user.email set to $email"
    [[ "$(git config --global init.defaultBranch 2>/dev/null)" != "main" ]] && git config --global init.defaultBranch main
    git config --global credential.helper &>/dev/null || { git config --global credential.helper libsecret &>/dev/null || git config --global credential.helper "cache --timeout=3600"; }
    [[ "$(git config --global commit.gpgsign 2>/dev/null)" == "true" ]] || {
        local key id; id=$(gpg --list-secret-keys --keyid-format LONG "$email" 2>/dev/null | grep ^sec | head -1 | sed 's/.*\///' | awk '{print $1}')
        [[ -n "$id" ]] && { git config --global user.signingkey "$id"; git config --global commit.gpgsign true; echo "gpg signing enabled key=$id"; } || echo "warning: no gpg key found for $email" >&2
    }
    echo "git configured"
}
