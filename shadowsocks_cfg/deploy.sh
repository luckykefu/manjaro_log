#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# ============================================================
#  Shadowsocks 一键部署脚本（分步骤输出）
#  用法: bash deploy.sh
# ============================================================
# ---------- 配置区 ----------
IP=202.182.112.91
PORT=1080
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"
# ---------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
step()  { echo -e "\n${CYAN}[STEP $1/$TOTAL]${NC} $2"; }
info()  { echo -e "  ${GREEN}->${NC} $1"; }
warn()  { echo -e "  ${YELLOW}WARN:${NC} $1"; }
err()   { echo -e "  ${RED}ERROR:${NC} $1"; }
TOTAL=8
# ============================================================
#  1. SSH 密钥推送
# ============================================================
step 1 "推送 SSH 公钥到远程服务器"
ssh-keygen -R "$IP" 2>/dev/null || true
ssh-copy-id -i ~/.ssh/id_ed25519.pub "root@$IP" &>/dev/null
info "完成"
# ============================================================
#  2. 服务端部署 Shadowsocks
# ============================================================
step 2 "服务端安装 shadowsocks-rust 并启动"
ssh root@$IP $SSH_OPTS bash -s -- "$IP" << 'SERVER_EOF' > /dev/null 2>&1
set -euo pipefail
IP=$1; PORT=8388; CFG_FILE="/etc/shadowsocks-rust/${IP}.json"
PASSWORD=$(openssl rand -base64 32)
sudo mkdir -p "$(dirname "$CFG_FILE")"
sudo tee "$CFG_FILE" > /dev/null << JSONEOF
{ "server": "0.0.0.0", "server_port": $PORT, "password": "$PASSWORD", "method": "2022-blake3-aes-256-gcm", "timeout": 300, "fast_open": true, "mode": "tcp_and_udp" }
JSONEOF
sudo pacman -S --noconfirm --needed shadowsocks-rust > /dev/null 2>&1
sudo systemctl enable --now "shadowsocks-rust-server@${IP}" > /dev/null 2>&1
sudo iptables -A INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true
sudo iptables -A INPUT -p udp --dport $PORT -j ACCEPT 2>/dev/null || true
SERVER_EOF
info "完成"
# ============================================================
#  3. 安装本地依赖
# ============================================================
step 3 "安装本地依赖 (shadowsocks-rust, openssh, jq)"
sudo pacman -S --needed --noconfirm shadowsocks-rust openssh jq > /dev/null 2>&1
info "完成"
# ============================================================
#  4. 拉取服务端配置文件
# ============================================================
step 4 "从远程服务器拉取 Shadowsocks 配置"
CFG_FILE="/etc/shadowsocks-rust/${IP}.json"
TMP=$(mktemp)
scp $SSH_OPTS "root@${IP}:${CFG_FILE}" "$TMP" > /dev/null 2>&1
CFG=$HOME/.shadowsocks/"${IP}".json
mkdir -p "$(dirname "$CFG")"
jq --arg ip "$IP" --arg port "$PORT" \
   'del(.mode) | .server = $ip | .local_address = "0.0.0.0" | .local_port = ($port | tonumber)' \
   "$TMP" > "$CFG"
rm "$TMP"
info "配置已保存至 $CFG"
# ============================================================
#  5. 清理旧 sslocal 进程
# ============================================================
step 5 "清理旧 sslocal 进程"
if [[ -f "$CFG.pid" ]]; then
  kill "$(cat "$CFG.pid")" 2>/dev/null || true
fi
pkill -x sslocal 2>/dev/null || true
for i in $(seq 1 10); do
  ss -tlnp | grep -q ":$PORT " || break
  sleep 1
done
info "完成"
# ============================================================
#  6. 启动新 sslocal
# ============================================================
step 6 "启动 sslocal 代理 (端口 $PORT)"
nohup sslocal -c "$CFG" > "${CFG}.log" 2>&1 &
PID=$!
echo $PID > "$CFG.pid"
sleep 1
if ! kill -0 $PID 2>/dev/null; then
  err "sslocal 启动失败，查看日志: ${CFG}.log"
  tail -5 "${CFG}.log" >&2
  exit 1
fi
info "sslocal 已启动 (PID: $PID)"
# ============================================================
#  7. 连通性测试
# ============================================================
step 7 "连通性测试 — 通过代理访问百度"
HTTP_CODE=$(curl -x socks5://127.0.0.1:$PORT -s -o /dev/null -w '%{http_code}' --connect-timeout 10 http://www.google.com 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
  echo -e "  ${GREEN}✓ 代理连通成功！google返回 $HTTP_CODE${NC}"
else
  echo -e "  ${RED}✗ 代理连通失败 (HTTP $HTTP_CODE)，请检查：${NC}"
  echo "    1) 服务端 shadowsocks 状态: ssh root@$IP 'systemctl status shadowsocks-rust-server@$IP'"
  echo "    2) 服务端端口 8388 是否放行"
  echo "    3) 本地日志: ${CFG}.log"
  exit 1
fi
# ============================================================
#  8. 完成
# ============================================================
step 8 "部署完成"
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Shadowsocks 部署成功！${NC}"
echo -e "${GREEN}  远程服务器 : $IP:8388${NC}"
echo -e "${GREEN}  本地 SOCKS5 : 127.0.0.1:$PORT${NC}"
echo -e "${GREEN}========================================${NC}"
