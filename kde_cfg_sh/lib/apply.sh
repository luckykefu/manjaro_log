#!/usr/bin/env bash
## Brief: Apply KDE lookandfeel packages via kwriteconfig6

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/config.sh"

cmd_apply() {
  ## Brief: Apply KDE lookandfeel settings
  ## Args: lookandfeel_package (optional)

  load_config

  local lookandfeel="${1:-org.kde.breeze.desktop}"

  log_info "Applying KDE lookandfeel: ${lookandfeel}"

  exec_cmd kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "${THEME_NAME}"
  exec_cmd kwriteconfig6 --file kcminputrc --group Keyboard --key repeatRate 30
  exec_cmd kwriteconfig6 --file kcminputrc --group Keyboard --key repeatDelay 250

  exec_cmd kwriteconfig6 --file kdeglobals --group General --key ColorScheme "${THEME_NAME}"
  exec_cmd kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "${lookandfeel}"

  exec_cmd kwriteconfig6 --file kiorc --group "Kill" --key "kill" "false"
  exec_cmd kwriteconfig6 --file kiorc --group "Confirmations" --key "ConfirmDelete" "false"

  exec_cmd kwriteconfig6 --file klaunchrc --group BusyCursor --key "BusyCursor" "false"

  exec_cmd kwriteconfig6 --file krunnerrc --group General --key FreeFloating true

  if command -v plasma-apply-lookandfeel &>/dev/null; then
    exec_cmd plasma-apply-lookandfeel -a "${lookandfeel}"
  fi

  log_success "KDE lookandfeel applied"
}
