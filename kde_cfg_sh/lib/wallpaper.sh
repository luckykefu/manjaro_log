#!/usr/bin/env bash
## Brief: Set KDE desktop wallpaper

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/config.sh"

cmd_wallpaper() {
  ## Brief: Apply wallpaper image
  ## Args: [wallpaper_path]

  load_config

  local wallpaper="${1:-${WALLPAPER_IMAGE}}"

  if [[ -z "${wallpaper}" ]]; then
    log_error "No wallpaper path specified. Set WALLPAPER_IMAGE env var or pass as argument."
    return 1
  fi

  if [[ ! -f "${wallpaper}" ]]; then
    log_error "Wallpaper file not found: ${wallpaper}"
    return 1
  fi

  log_info "Setting wallpaper: ${wallpaper}"

  if command -v plasma-apply-wallpaperimage &>/dev/null; then
    exec_cmd plasma-apply-wallpaperimage "${wallpaper}"
    log_success "Wallpaper applied via plasma-apply-wallpaperimage"
  else
    log_warn "plasma-apply-wallpaperimage not found, using kwriteconfig6 fallback"

    local wallpaper_abs
    wallpaper_abs="$(realpath "${wallpaper}")"

    exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group "Containments" --group "1" --group "Wallpaper" \
      --group "org.kde.image" --group "General" --key "Image" "file://${wallpaper_abs}"

    exec_cmd kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group "Containments" --group "1" --group "Wallpaper" \
      --group "org.kde.image" --group "General" --key "FillMode" "2"

    log_info "Wallpaper config written. Restart plasma-shell to apply: kquitapp6 plasmashell && kstart plasmashell"
  fi

  if [[ -d "${WALLPAPER_PATH}" ]]; then
    exec_cmd cp "${wallpaper}" "${WALLPAPER_PATH}/"
    log_info "Copied wallpaper to ${WALLPAPER_PATH}"
  fi

  log_success "Wallpaper set"
}
