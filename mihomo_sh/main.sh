#!/bin/bash
set -euo pipefail

# ============================================================
# main.sh — Entry point
# ============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  lib_main "$@"
fi
