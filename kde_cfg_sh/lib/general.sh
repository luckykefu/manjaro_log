#!/usr/bin/env bash
## Brief: Apply general KDE system settings

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/config.sh"

cmd_general() {
  ## Brief: Configure general KDE settings (fonts, input, shortcuts)
  ## Args: none

  load_config

  log_info "Applying general KDE settings"

  exec_cmd kwriteconfig6 --file kdeglobals --group "General" --key "font" "Noto Sans,10,-1,5,50,0,0,0,0,0"
  exec_cmd kwriteconfig6 --file kdeglobals --group "General" --key "fixed" "Noto Sans Mono,10,-1,5,50,0,0,0,0,0"
  exec_cmd kwriteconfig6 --file kdeglobals --group "General" --key "smallestReadableFont" "Noto Sans,8,-1,5,50,0,0,0,0,0"
  exec_cmd kwriteconfig6 --file kdeglobals --group "General" --key "toolBarStyle" "TextBesideIcon"
  exec_cmd kwriteconfig6 --file kdeglobals --group "General" --key "widgetStyle" "Breeze"
  exec_cmd kwriteconfig6 --file kdeglobals --group "General" --key "shadeSortColumn" "true"

  exec_cmd kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnLeft" "false"
  exec_cmd kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "CloseOnDoubleClickOnMenu" "false"

  exec_cmd kwriteconfig6 --file kxkbrc --group "Layout" --key "DisplayNames" ","
  exec_cmd kwriteconfig6 --file kxkbrc --group "Layout" --key "LayoutList" "us"
  exec_cmd kwriteconfig6 --file kxkbrc --group "Layout" --key "VariantList" ","

  exec_cmd kwriteconfig6 --file breezerc --group "Common" --key "ShadowSize" "ShadowVeryLarge"
  exec_cmd kwriteconfig6 --file breezerc --group "Common" --key "OutlineOpacity" "0.4"

  exec_cmd kwriteconfig6 --file touchpadrc --group "Touchpad" --key "disableWhileTyping" "true"
  exec_cmd kwriteconfig6 --file touchpadrc --group "Touchpad" --key "tapToClick" "true"
  exec_cmd kwriteconfig6 --file touchpadrc --group "Touchpad" --key "naturalScroll" "true"
  exec_cmd kwriteconfig6 --file touchpadrc --group "Touchpad" --key "scrollInverted" "false"

  exec_cmd kwriteconfig6 --file dolphinrc --group "General" --key "ShowSelectionToggle" "false"
  exec_cmd kwriteconfig6 --file dolphinrc --group "General" --key "VersionControlEnabled" "true"
  exec_cmd kwriteconfig6 --file dolphinrc --group "Preview" --key "ShowPreview" "true"
  exec_cmd kwriteconfig6 --file dolphinrc --group "Preview" --key "ShowThumbnails" "true"

  exec_cmd kwriteconfig6 --file kscreensaverrc --group "Daemon" --key "Autolock" "false"
  exec_cmd kwriteconfig6 --file kscreensaverrc --group "Daemon" --key "LockGrace" "0"
  exec_cmd kwriteconfig6 --file kscreensaverrc --group "Daemon" --key "Timeout" "900"

  exec_cmd kwriteconfig6 --file klaunchrc --group "FeedbackStyle" --key "TaskbarButton" "true"
  exec_cmd kwriteconfig6 --file klaunchrc --group "FeedbackStyle" --key "TaskbarButtonHighlight" "true"

  exec_cmd kwriteconfig6 --file klipperrc --group "General" --key "KeepClipboardContent" "true"
  exec_cmd kwriteconfig6 --file klipperrc --group "General" --key "MaxClipItems" "50"

  log_success "General KDE settings applied"
}
