#!/bin/bash
set -euo pipefail

# ============================================================
# main.sh — Entry point: SSH reverse proxy
# ============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib.sh"

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && lib_main "$@"
