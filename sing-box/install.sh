#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || err "请以 root 身份运行"

command -v openssl >/dev/null || err "openssl 未安装"
command -v curl >/dev/null   || err "curl 未安装"

if ! command -v sing-box &>/dev/null; then
  info "安装 sing-box..."
  bash <(curl -fsSL https://sing-box.app/install.sh)
else
  info "sing-box 已安装 $(sing-box version | head -1)"
fi
