symlink() {
    local src="$1" dst="$2"
    [[ ! -e "$src" ]] && { echo "error: src not found: $src" >&2; return 1; }
    [[ -e "$dst" || -L "$dst" ]] && { local bak="${dst}.bak"; [[ -e "$bak" || -L "$bak" ]] && rm -rf "$bak"; mv "$dst" "$bak" && echo "backed up $dst -> $bak"; }
    ln -sf "$src" "$dst" && echo "linked $dst -> $src"
}
