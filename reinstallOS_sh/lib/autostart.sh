# shellcheck shell=bash
_autostart_find_desktop() {
    local app="${1%.desktop}" dirs=(
        /usr/share/applications
        /usr/local/share/applications
        "$HOME/.local/share/applications"
    )
    for d in "${dirs[@]}"; do
        [[ -f "$d/$app.desktop" ]] && { echo "$d/$app.desktop"; return 0; }
    done
    local bin; bin=$(which "$app" 2>/dev/null) || return 1
    local bin_name; bin_name=$(basename "$bin")
    for d in "${dirs[@]}"; do
        [[ -d "$d" ]] || continue
        local found; found=$(find "$d" -iname "*${bin_name}*" -name "*.desktop" -print -quit 2>/dev/null)
        [[ -n "$found" ]] && { echo "$found"; return 0; }
    done
    return 1
}

autostart() {
    local apps=("org.cryptomator.Cryptomator.desktop" "org.kde.ksshaskpass.desktop")
    [[ ${#apps[@]} -eq 0 ]] && { echo "error: no apps provided" >&2; return 1; }
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    for app in "${apps[@]}"; do
        local desktop=$(_autostart_find_desktop "$app") || { echo "warning: desktop file not found for $app" >&2; continue; }
        local target="$autostart_dir/$(basename "$desktop")"
        [[ -L "$target" && "$(readlink "$target")" == "$desktop" ]] && { echo "autostart ok: $app"; continue; }
        ln -sf "$desktop" "$target" && echo "autostart linked: $app ($(basename "$desktop"))"
    done
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]] ;then
    autostart
fi
