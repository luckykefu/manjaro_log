autostart() {
    local apps=("$@")
    [[ ${#apps[@]} -eq 0 ]] && { echo "error: no apps provided" >&2; return 1; }
    local autostart_dir="$HOME/.config/autostart"; mkdir -p "$autostart_dir"
    for app in "${apps[@]}"; do
        local exact="/usr/share/applications/${app}.desktop"
        if [[ -f "$exact" ]]; then
            local bak="${autostart_dir}/${app}.desktop.bak"
            [[ -f "$bak" ]] && rm -f "$bak"
            [[ -f "$autostart_dir/${app}.desktop" ]] && mv "$autostart_dir/${app}.desktop" "$bak"
            ln -sf "$exact" "$autostart_dir/${app}.desktop" && echo "autostart linked: $app"
        else
            local found
            found=$(find /usr/share/applications -name "*.desktop" 2>/dev/null | while IFS= read -r f; do
                base=$(basename "$f" .desktop | tr [:upper:] [:lower:] | tr -dc [:alnum:])
                app_norm=$(echo "$app" | tr [:upper:] [:lower:] | tr -dc [:alnum:])
                echo "$base" | grep -q "$app_norm" && echo "$f" && break
            done)
            [[ -n "$found" ]] && { local target="$autostart_dir/$(basename "$found")"; local bak="${target}.bak"; [[ -f "$bak" ]] && rm -f "$bak"; [[ -f "$target" ]] && mv "$target" "$bak"; ln -sf "$found" "$target" && echo "autostart linked: $(basename "$found")"; } || echo "warning: desktop file not found for $app" >&2
        fi
    done
    echo "autostart configured for ${#apps[@]} app(s)"
}
