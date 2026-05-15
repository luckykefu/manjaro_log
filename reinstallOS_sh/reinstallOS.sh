#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/theme.sh"
source "$SCRIPT_DIR/lib/sudo.sh"
source "$SCRIPT_DIR/lib/mirrors.sh"
source "$SCRIPT_DIR/lib/fstrim.sh"
source "$SCRIPT_DIR/lib/timezone.sh"
source "$SCRIPT_DIR/lib/chown.sh"
source "$SCRIPT_DIR/lib/display.sh"
source "$SCRIPT_DIR/lib/ssh.sh"
source "$SCRIPT_DIR/lib/gpg.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/zshrc.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/aur.sh"
source "$SCRIPT_DIR/lib/fcitx5.sh"
source "$SCRIPT_DIR/lib/autostart.sh"
source "$SCRIPT_DIR/lib/update.sh"
source "$SCRIPT_DIR/lib/shadowsocks.sh"
source "$SCRIPT_DIR/lib/pacman_cfg.sh"

main() {
    local subcommand="${1:-help}"
    shift 2>/dev/null || true

    case "$subcommand" in
        theme)      cmd_theme "$@" ;;
        sudo)       cmd_sudo "$@" ;;
        mirrors)    cmd_mirrors "$@" ;;
        fstrim)     cmd_fstrim "$@" ;;
        timezone)   cmd_timezone "$@" ;;
        chown)      cmd_chown "$@" ;;
        display)    cmd_display "$@" ;;
        ssh)        cmd_ssh "$@" ;;
        gpg)        cmd_gpg "$@" ;;
        git)        cmd_git "$@" ;;
        zshrc)      cmd_zshrc "$@" ;;
        packages)   cmd_packages "$@" ;;
        aur)        cmd_aur "$@" ;;
        fcitx5)     cmd_fcitx5 "$@" ;;
        autostart)  cmd_autostart "$@" ;;
        update)     cmd_update "$@" ;;
        shadowsocks) cmd_shadowsocks "$@" ;;
        pacman_cfg) cmd_pacman_cfg "$@" ;;
        help|--help|-h)
            echo "Usage: $(basename "$0") <subcommand> [args...]"
            echo ""
            echo "Available subcommands:"
            echo "  theme       Configure theme"
            echo "  sudo        Copy sudoers config"
            echo "  mirrors     Configure mirrors"
            echo "  fstrim      Enable fstrim timer"
            echo "  timezone    Set timezone"
            echo "  chown       Chown home directory"
            echo "  display     Copy display config files"
            echo "  ssh         Copy SSH keys and enable sshd"
            echo "  gpg         Copy and import GPG keys"
            echo "  git         Configure git"
            echo "  zshrc       Copy .zshrc"
            echo "  packages    Install packages via pacman"
            echo "  aur         Install yay AUR helper"
            echo "  fcitx5      Copy fcitx5 config"
            echo "  autostart   Copy autostart entries"
            echo "  update      Run pacman -Syyu"
            echo "  shadowsocks Copy shadowsocks config and enable service"
            echo "  pacman_cfg  Copy pacman.conf"
            ;;
        *)
            log_error "Unknown subcommand: $subcommand"
            exit 1
            ;;
    esac
}

main "$@"
