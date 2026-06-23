#!/usr/bin/env bash
set -euo pipefail
# ============================================================
# sing-box 一键部署（4 阶段）
#   本机（GCP 35.239.153.114）→ 服务端
#   远程（100.75.45.52）      → 客户端
# 用法: sudo bash deploy.sh
# ============================================================

[[ $EUID -eq 0 ]] || { echo "[ERROR] 请以 root 身份运行" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

REMOTE_USER="${REMOTE_USER:-lkf}"
REMOTE_HOST="${REMOTE_HOST:-100.75.45.52}"
# 使用 tailscale IP 避免 GCP 防火墙阻挡
SERVER_IP="${SERVER_IP:-100.66.66.0}"

# ============================================================
echo -e "\n===== 阶段 1/4: 安装 sing-box ====="
# ============================================================
echo "[INFO] 本机（服务端）..."
bash "${SCRIPT_DIR}/install.sh"

echo "[INFO] 远程（客户端 ${REMOTE_HOST}）..."
tailscale ssh "${REMOTE_USER}@${REMOTE_HOST}" "sudo bash -s" < "${SCRIPT_DIR}/install.sh"

# ============================================================
echo -e "\n===== 阶段 2/4: 服务端部署（本机）====="
# ============================================================
echo "[INFO] 生成密钥材料..."
eval "$(bash "${SCRIPT_DIR}/gen-keys.sh")"

echo "[INFO] 生成服务端配置..."
export PRIVATE_KEY PUBLIC_KEY VLESS_UUID TUIC_UUID TUIC_PASSWORD SHORT_ID
bash "${SCRIPT_DIR}/gen-server-config.sh"

echo "[INFO] 启动服务端..."
bash "${SCRIPT_DIR}/start-server.sh"

# ============================================================
echo -e "\n===== 阶段 3/4: 客户端部署（远程 ${REMOTE_HOST}）====="
# ============================================================
echo "[INFO] 推送客户端配置到远程..."

# 构建客户端配置所需的变量
export SERVER_IP VLESS_PORT="${VLESS_PORT:-443}" VLESS_UUID PUBLIC_KEY SHORT_ID
export TUIC_PORT="${TUIC_PORT:-8443}" TUIC_UUID TUIC_PASSWORD

# 本地生成客户端配置文件，再推送到远程
CLIENT_JSON=$(mktemp)
CONFIG_DIR=/tmp/sing-box-client bash "${SCRIPT_DIR}/gen-client-config.sh" > /dev/null 2>&1
cat /tmp/sing-box-client/client.json > "$CLIENT_JSON"
rm -rf /tmp/sing-box-client

# 推送到远程
tailscale ssh "${REMOTE_USER}@${REMOTE_HOST}" "
  sudo mkdir -p /etc/sing-box
  sudo tee /etc/sing-box/client.json > /dev/null
" < "$CLIENT_JSON"

rm -f "$CLIENT_JSON"

echo "[INFO] 推送启动脚本..."
tailscale ssh "${REMOTE_USER}@${REMOTE_HOST}" "sudo mkdir -p /data/.manjaro/sing-box"
tailscale ssh "${REMOTE_USER}@${REMOTE_HOST}" "sudo bash -s" < "${SCRIPT_DIR}/start-client.sh"

echo "[INFO] 在远程启动客户端..."
tailscale ssh "${REMOTE_USER}@${REMOTE_HOST}" "
  export CONFIG_DIR=/etc/sing-box
  export MIXED_PORT=1080
  sudo bash /data/.manjaro/sing-box/start-client.sh
"

# ============================================================
echo -e "\n===== 阶段 4/4: 验证连通性 ====="
# ============================================================
echo "[INFO] 从远程测试代理..."
tailscale ssh "${REMOTE_USER}@${REMOTE_HOST}" "
  bash -c '
    echo \"[INFO] 测试 socks5://127.0.0.1:1080 ...\"
    HTTP_CODE=\\\$(curl --socks5-hostname 127.0.0.1:1080 -s -o /dev/null -w \"%{http_code}\" --connect-timeout 10 https://www.gstatic.com/generate_204 2>/dev/null || echo \"000\")
    if [[ \"\\\$HTTP_CODE\" == \"204\" ]]; then
      echo \"[INFO] 结果: 204 — VLESS+Reality 代理正常\"
    else
      echo \"[ERROR] 结果: \\\$HTTP_CODE — 代理异常\"
    fi
  '
"

echo ""
echo "============================================"
echo "  部署完成!"
echo "============================================"
echo ""
echo "服务端（本机 ${SERVER_IP}）:"
echo "  VLESS+Reality :${VLESS_PORT}  UUID=${VLESS_UUID}"
echo "  TUIC          :${TUIC_PORT}  Password=${TUIC_PASSWORD}"
echo ""
echo "客户端（${REMOTE_HOST}）:"
echo "  混合代理 127.0.0.1:1080"
echo ""
echo "客户端配置: /etc/sing-box/client.json"
echo "服务端配置: /etc/sing-box/config.json"
echo "============================================"
