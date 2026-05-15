display() {
    local output="${1:-}"
    local rate="${2:-60}"
    [[ -z "$output" ]] && { echo "error: output id required" >&2; return 1; }
    ! command -v kscreen-doctor &>/dev/null && { echo "error: kscreen-doctor not found" >&2; return 1; }
    local uid; uid=$(id -u)
    [[ -z "${WAYLAND_DISPLAY:-}" ]] && { local sock; sock=$(find /run/user/"$uid" -maxdepth 1 -name "wayland-*" -print -quit 2>/dev/null); [[ -n "$sock" ]] && export WAYLAND_DISPLAY=$(basename "$sock"); }
    [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && { local dbus="/run/user/$uid/bus"; [[ -f "$dbus" ]] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus"; }
    local out; out=$(kscreen-doctor -o 2>/dev/null)
    local target_rate="$rate" best_mid="" best_area=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "Modes:"; then
            for entry in $(echo "$line" | grep -oP '\d+:[0-9x@.]+'); do
                local mid="${entry%%:*}" rest="${entry#*:}" res="${rest%@*}" entry_rate="${rest#*@}"
                entry_rate="${entry_rate%%.*}"; local w="${res%x*}" h="${res#*x}" area=$((w * h))
                [[ "$entry_rate" == "$target_rate" || $((entry_rate - target_rate)) -lt 2 && $((target_rate - entry_rate)) -lt 2 ]] && [[ $area -gt $best_area ]] && { best_area=$area; best_mid=$mid; }
            done
        fi
    done <<< "$out"
    [[ -z "$best_mid" ]] && { echo "error: no ${rate}Hz mode found" >&2; return 1; }
    kscreen-doctor "output.${output}.mode.${best_mid}"
    echo "set output $output to ${rate}Hz (mode $best_mid)"
}
