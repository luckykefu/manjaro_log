#!/bin/bash

# Shadowsocks 服务器配置脚本
# 参数：
#   $1: 密码 (必需)
#   $2: 端口 (可选，默认 8388)
#   $3: 加密方式 (可选，默认 aes-256-gcm)
#   $4: 配置文件名 (可选，默认 config)

setup_shadowsocks_server() {
    local password="$1"
    local port="${2:-8388}"
    local method="${3:-aes-256-gcm}"
    local config_name="${4:-config}"

    # 检查必需参数
    if [ -z "$password" ]; then
        echo "❌ 错误: 密码是必需的"
        echo "用法: $0 <密码> [端口] [加密方式] [配置名]"
        return 1
    fi

    echo "🔧 安装 Shadowsocks..."
    sudo pacman -S shadowsocks --noconfirm --needed

    echo "📝 创建配置文件..."
    sudo mkdir -p /etc/shadowsocks

    sudo tee "/etc/shadowsocks/${config_name}.json" > /dev/null << EOF
{
    "server": "0.0.0.0",
    "server_port": $port,
    "password": "$password",
    "method": "$method",
    "timeout": 300,
    "fast_open": false,
    "mode": "tcp_and_udp"
}
EOF

    echo "🚀 启动并设置开机自启..."
    sudo systemctl enable --now "shadowsocks-server@${config_name}"

    echo "🔥 配置防火墙..."
    sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
    sudo iptables -A INPUT -p udp --dport "$port" -j ACCEPT

    # 保存防火墙规则
    sudo mkdir -p /etc/iptables
    sudo iptables-save > /etc/iptables/iptables.rules

    echo "✅ 部署完成！"
    echo "📊 服务状态:"
    sudo systemctl status "shadowsocks-server@${config_name}" --no-pager

    echo ""
    echo "📋 配置信息:"
    sudo cat "/etc/shadowsocks/${config_name}.json"

    echo ""
    echo "🔗 连接信息:"
    echo "  服务器: $(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP')"
    echo "  端口: $port"
    echo "  密码: $password"
    echo "  加密: $method"
}

# 显示帮助
show_help() {
    cat << EOF
Shadowsocks 服务器配置工具

用法:
  $0 <密码> [端口] [加密方式] [配置名]

参数:
  密码      必需，连接密码
  端口      可选，默认 8388
  加密方式   可选，默认 aes-256-gcm
  配置名    可选，默认 config

示例:
  $0 mypassword123                    # 使用默认端口和加密
  $0 mypassword123 9999               # 指定端口
  $0 mypassword123 9999 chacha20-ietf-poly1305  # 指定加密方式
  $0 mypassword123 9999 aes-256-gcm myserver     # 指定配置名

常用加密方式:
  - aes-256-gcm (推荐)
  - chacha20-ietf-poly1305 (推荐)
  - aes-128-gcm
EOF
}

# 检查是否被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            setup_shadowsocks_server "$@"
            ;;
    esac
fi
