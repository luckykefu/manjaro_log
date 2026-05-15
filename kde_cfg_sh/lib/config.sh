#!/usr/bin/env bash
## Brief: Load environment configuration for KDE setup

load_config() {
  ## Brief: Load configuration from environment variables or defaults
  ## Args: path to .env file (optional)

  local env_file="${1:-}"

  if [[ -n "${env_file}" ]] && [[ -f "${env_file}" ]]; then
    set -a
    source "${env_file}"
    set +a
  fi

  THEME_REPO="${THEME_REPO:-https://github.com/tsbohc/catppuccin-kde.git}"
  THEME_BRANCH="${THEME_BRANCH:-main}"
  THEME_NAME="${THEME_NAME:-Catppuccin-Mocha}"

  THEME_DIR="${THEME_DIR:-${HOME}/.local/share/plasma/desktoptheme}"
  COLOR_SCHEMES_DIR="${COLOR_SCHEMES_DIR:-${HOME}/.local/share/color-schemes}"
  AURORAE_DIR="${AURORAE_DIR:-${HOME}/.local/share/aurorae/themes}"
  KVANTUM_DIR="${KVANTUM_DIR:-${HOME}/.config/Kvantum}"
  ICONS_DIR="${ICONS_DIR:-${HOME}/.local/share/icons}"
  SDDM_DIR="${SDDM_DIR:-/usr/share/sddm/themes}"
  LOOKANDFEEL_DIR="${LOOKANDFEEL_DIR:-${HOME}/.local/share/plasma/look-and-feel}"

  WALLPAPER_PATH="${WALLPAPER_PATH:-${HOME}/.local/share/wallpapers}"
  WALLPAPER_IMAGE="${WALLPAPER_IMAGE:-}"

  CLOCK_FORMAT="${CLOCK_FORMAT:-24h}"
  DATE_FORMAT="${DATE_FORMAT:-iso}"

  export THEME_REPO THEME_BRANCH THEME_NAME
  export THEME_DIR COLOR_SCHEMES_DIR AURORAE_DIR KVANTUM_DIR ICONS_DIR SDDM_DIR LOOKANDFEEL_DIR
  export WALLPAPER_PATH WALLPAPER_IMAGE
  export CLOCK_FORMAT DATE_FORMAT
}
