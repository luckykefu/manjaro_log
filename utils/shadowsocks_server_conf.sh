#!/bin/bash
set -euo pipefail  # 严格模式

# Shadowsocks 服务器配置脚本
# 参数：
#   $1: 密码 (必需)
#   $2: 配置名 (可选，默认 config)

readonly SCRIPT_NAME="$(basename "$0")"
readonly SS_CONFIG_DIR="/etc/shadowsocks"
readonly DEFAULT_PORT=8388
readonly DEFAULT_METHOD="aes-256-gcm"

log_info() { echo "ℹ️  $*"; }
log_success() { echo "✅ $*"; }
log_error() { echo "❌ 错误: $*" >&2; }

setup_shadowsocks_server() {
    local password="$1"
    local config_name="${2:-config}"
    local server_ip

    # 验证参数
    if [[ -z "$password" ]]; then
        log_error "密码是必需的"
        show_help
        return 1
    fi

    # 检查是否为 root
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限"
        return 1
    fi

    log_info "安装 Shadowsocks..."
    pacman -S shadowsocks --noconfirm --needed || {
        log_error "安装失败"
        return 1
    }

    log_info "创建配置文件..."
    mkdir -p "$SS_CONFIG_DIR"

    cat > "${SS_CONFIG_DIR}/${config_name}.json" << EOF
{
    "server": "0.0.0.0",
    "server_port": $DEFAULT_PORT,
    "password": "$password",
    "method": "$DEFAULT_METHOD",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF

    log_info "启动服务..."
    systemctl enable --now "shadowsocks-server@${config_name}" || {
        log_error "服务启动失败"
        return 1
    }

    log_info "配置防火墙..."
    if command -v firewall-cmd &> /dev/null; then
        # firewalld
        firewall-cmd --permanent --add-port="${DEFAULT_PORT}/tcp"
        firewall-cmd --permanent --add-port="${DEFAULT_PORT}/udp"
        firewall-cmd --reload
    elif command -v ufw &> /dev/null; then
        # ufw
        ufw allow "$DEFAULT_PORT"
    else
        # iptables
        iptables -A INPUT -p tcp --dport "$DEFAULT_PORT" -j ACCEPT
        iptables -A INPUT -p udp --dport "$DEFAULT_PORT" -j ACCEPT
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/iptables.rules
    fi

    log_success "部署完成！"
    
    # 获取服务器 IP
    server_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "获取失败")
    
    echo ""
    echo "📋 配置信息:"
    cat "${SS_CONFIG_DIR}/${config_name}.json"
    
    echo ""
    echo "🔗 连接信息:"
    echo "  服务器: $server_ip"
    echo "  端口: $DEFAULT_PORT"
    echo "  密码: $password"
    echo "  加密: $DEFAULT_METHOD"
    
    echo ""
    echo "📊 服务状态:"
    systemctl status "shadowsocks-server@${config_name}" --no-pager -l
}

show_help() {
    cat << EOF
Shadowsocks 服务器配置工具

用法:
  $SCRIPT_NAME <密码> [配置名]

参数:
  密码      必需，连接密码
  配置名    可选，默认 config

示例:
  $SCRIPT_NAME mypassword123
  $SCRIPT_NAME mypassword123 myserver

注意:
  - 需要 root 权限运行
  - 默认端口: $DEFAULT_PORT
  - 默认加密: $DEFAULT_METHOD
EOF
}

# 主程序
main() {
    case "${1:-help}" in
        help|-h|--help)
            show_help
            ;;
        *)
            setup_shadowsocks_server "$@"
            ;;
    esac
}

# 仅在直接执行时运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
