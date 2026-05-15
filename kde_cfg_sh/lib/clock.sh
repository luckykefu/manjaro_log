#!/usr/bin/env bash
## Brief: Configure KDE clock format

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/config.sh"

cmd_clock() {
  ## Brief: Set clock and date format
  ## Args: [clock_format] [date_format]

  load_config

  local clock_fmt="${1:-${CLOCK_FORMAT}}"
  local date_fmt="${2:-${DATE_FORMAT}}"

  log_info "Setting clock format: ${clock_fmt}, date format: ${date_fmt}"

  if [[ "${clock_fmt}" == "24h" ]]; then
    exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group "Containments" --group "1" --group "Applets" --group "2" \
      --group "CompactApplet" --key "showSeconds" "true"
    exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group "Containments" --group "1" --group "Applets" --group "2" \
      --group "Configuration" --key "use24hFormat" "true"
  else
    exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group "Containments" --group "1" --group "Applets" --group "2" \
      --group "Configuration" --key "use24hFormat" "false"
  fi

  case "${date_fmt}" in
    iso)
      exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group "Containments" --group "1" --group "Applets" --group "2" \
        --group "Configuration" --key "dateFormat" "isoDate"
      ;;
    full)
      exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group "Containments" --group "1" --group "Applets" --group "2" \
        --group "Configuration" --key "dateFormat" "fullDate"
      ;;
    short)
      exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group "Containments" --group "1" --group "Applets" --group "2" \
        --group "Configuration" --key "dateFormat" "shortDate"
      ;;
    *)
      log_warn "Unknown date format: ${date_fmt}"
      ;;
  esac

  exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
    --group "Containments" --group "1" --group "Applets" --group "2" \
    --group "Configuration" --key "showDate" "true"

  log_success "Clock format configured"
}
