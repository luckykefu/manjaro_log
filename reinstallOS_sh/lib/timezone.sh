timezone() {
    local tz="${1:-UTC}"
    echo "setting timezone to $tz"
    sudo timedatectl set-timezone "$tz"
    sudo timedatectl set-ntp true
    echo "timezone set to $tz"
}
