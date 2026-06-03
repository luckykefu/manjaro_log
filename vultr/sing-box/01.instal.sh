#!/usr/bin/env bash
set -euxo pipefail
bash <(curl -fsSL https://sing-box.app/install.sh) "${@}"
