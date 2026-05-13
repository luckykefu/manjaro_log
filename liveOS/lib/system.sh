#!/usr/bin/env bash
set -euo pipefail

apply_theme() {
    info "应用主题..."
    lookandfeeltool -a org.manjaro.breath-dark.desktop
}
