#!/usr/bin/env bash
## Brief: KDE desktop configuration manager
## Args: subcommand [options]
##   theme    - Install and apply KDE theme
##   apply    - Apply KDE lookandfeel settings
##   clock    - Configure clock format
##   wallpaper - Set desktop wallpaper
##   general  - Apply general KDE system settings

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SELF_DIR}/lib/common.sh"

main() {
  local subcommand="${1:-}"
  shift 2>/dev/null || true

  case "${subcommand}" in
    theme)
      cmd_theme "$@"
      ;;
    apply)
      cmd_apply "$@"
      ;;
    clock)
      cmd_clock "$@"
      ;;
    wallpaper)
      cmd_wallpaper "$@"
      ;;
    general)
      cmd_general "$@"
      ;;
    *)
      echo "Usage: $0 {theme|apply|clock|wallpaper|general}" >&2
      exit 1
      ;;
  esac
}

main "$@"
