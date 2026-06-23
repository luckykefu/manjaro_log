#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

PROXY="${PROXY:-socks5h://127.0.0.1:1080}"

info "测试 ${PROXY} ..."

HTTP_CODE=$(curl --socks5-hostname "$PROXY" -s -o /dev/null -w '%{http_code}' --connect-timeout 10 https://www.gstatic.com/generate_204 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "204" ]]; then
  info "结果: 204 — VLESS+Reality 代理正常"
else
  err "结果: ${HTTP_CODE} — 代理异常"
fi

HTTP_CODE=$(curl --socks5-hostname "$PROXY" -s -o /dev/null -w '%{http_code}' --connect-timeout 10 https://www.google.com 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  info "结果: 200 — 网页访问正常"
else
  info "结果: ${HTTP_CODE} — 网页访问异常（可能被路由规则拦截）"
fi

info "连通性验证完成"
