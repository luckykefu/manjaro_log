#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"

## Brief: Print usage information
usage() {
  cat <<USAGE
Usage: $(basename "$0") <command> [args]

Commands:
  gen [url]         Generate mihomo config from subscription URL
  check             Check mihomo connectivity

Environment:
  CONFIG_URL        Default subscription URL (used by gen if no arg given)
  MIHOMO_CONFIG     Output config path (default: /etc/mihomo/config.yaml)
USAGE
}

main() {
  [[ $# -ge 1 ]] || { usage; die "A subcommand is required"; }

  local cmd=$1
  shift

  case "$cmd" in
    gen)
      source "$SCRIPT_DIR/lib/subscribe.sh"
      source "$SCRIPT_DIR/lib/parser.sh"
      source "$SCRIPT_DIR/lib/config.sh"
      cmd_gen "$@"
      ;;
    check)
      source "$SCRIPT_DIR/lib/check.sh"
      cmd_check "$@"
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      die "Unknown subcommand: $cmd"
      ;;
  esac
}

main "$@"
