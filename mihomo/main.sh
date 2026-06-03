#!/bin/bash

# 切换到脚本目录（原注释未实现，现改为切换到脚本所在目录）
cd "$(dirname "$0")" || exit 1
pwd
# 安装 mihomo
sudo pacman -S --needed --noconfirm mihomo yq &> /dev/null

readonly CONFIG="config.yaml"
readonly BOOTSTRAP_PROXY="http://127.0.0.1:7890"
readonly url=${1}

# 判断是否需要下载配置
if [ -z "$url" ]; then
    # 没有提供 URL，检查本地配置文件是否存在
    if [ -f "$CONFIG" ]; then
        echo "使用本地配置文件: $CONFIG"
    else
        echo "错误: 未提供配置 URL 且本地不存在 $CONFIG，请提供 URL 或手动放置配置文件。"
        exit 1
    fi
else
    # 提供 URL，尝试下载
    echo "正在下载配置: $url"
    if curl -x "$BOOTSTRAP_PROXY" -sLfA 'clash.meta' --connect-timeout 10 --max-time 30 --retry 2 -o "$CONFIG" "$url"; then
        echo "下载成功"
        # 添加 TUN 配置
        yq -i -y '.tun = {"enable": true, "stack": "mixed", "dns-hijack": ["any:53"], "auto-route": true, "auto-redir": true}' "$CONFIG"
    else
        echo "下载失败，请检查 URL 或代理 $BOOTSTRAP_PROXY 是否可用"
        exit 1
    fi
fi

# 停止已有 mihomo 进程
sudo pkill mihomo  || true

# 后台启动 mihomo
nohup sudo mihomo -d "$(dirname "$CONFIG")" > "${CONFIG}.log" 2>&1 &

# 验证启动成功（端口监听）
readonly port=$(yq -r '.["mixed-port"] // 7890' "$CONFIG")
for (( i=1; i<=5; i++ )); do
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo "mihomo 已监听端口 $port"
        break
    fi
    echo "等待端口 $port 启动... ($i/5)"
    sleep 1
    if [ $i -eq 5 ]; then
        echo "错误: mihomo 未能在 5 秒内启动"
        exit 1
    fi
done

# 验证网络连通性（通过代理访问 google.com）
http_code=$(curl -sx "http://127.0.0.1:$port" -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://www.google.com" 2>/dev/null || echo "000")
if [ "$http_code" = "200" ]; then
    echo "代理测试成功 (HTTP 200)"
else
    echo "警告: 代理测试返回 HTTP $http_code，请检查配置"
fi

# # 开放本地端口，允许局域网连接（谨慎：先放行 SSH）
# sudo pacman -S --needed --noconfirm ufw
# sudo ufw allow ssh 2>/dev/null || true   # 先允许 SSH，防止远程断开
# sudo ufw allow "$port/tcp" 2>/dev/null || true
# sudo ufw --force enable 2>/dev/null || true

echo "mihomo 启动完成，代理端口: $port (HTTP/Socks 混合)"
