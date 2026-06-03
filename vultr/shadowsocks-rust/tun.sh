#!/usr/bin/env zsh
set -euo pipefail

readonly CFG="/etc/shadowsocks-rust/config.json"

cmd_start() {
    # 清理旧进程
    sudo pkill -x sslocal 2>/dev/null || true
    sudo pkill -x tun2proxy 2>/dev/null || true
    sleep 1

    echo "启动 sslocal (SOCKS5)…"
    nohup sudo sslocal -c "$CFG" > /dev/null 2>&1 &
    sleep 2

    echo "启动 tun2proxy…"
    sudo rm -f /tmp/tun2proxy.log
    sudo bash -c 'nohup tun2proxy \
        --proxy socks5://127.0.0.1:1080 \
        --setup \
        --dns virtual \
        --verbosity info \
        > /dev/null 2> /tmp/tun2proxy.log </dev/null &'
    sleep 2

    # 验证
    pgrep -x sslocal  > /dev/null && echo "  sslocal    OK" || echo "  sslocal    FAIL"
    pgrep -x tun2proxy > /dev/null && echo "  tun2proxy  OK" || echo "  tun2proxy  FAIL"

    # 恢复 DNS（tun2proxy --setup 可能改了 resolv.conf，确保是 10.0.0.1）
    echo "nameserver 10.0.0.1" | sudo tee /etc/resolv.conf > /dev/null

    echo "代理已启动 ✓"
}

cmd_stop() {
    echo "停止代理…"
    sudo pkill -x tun2proxy 2>/dev/null || true
    sudo pkill -x sslocal 2>/dev/null || true
    sleep 1

    # 清理路由和 TUN 接口
    sudo ip route del 0.0.0.0/1 2>/dev/null || true
    sudo ip route del 128.0.0.0/1 2>/dev/null || true
    sudo ip link del tun0 2>/dev/null || true

    # 恢复 DNS
    if mountpoint -q /etc/resolv.conf 2>/dev/null; then
        sudo umount /etc/resolv.conf 2>/dev/null || true
    fi
    echo "nameserver 192.168.1.1" | sudo tee /etc/resolv.conf > /dev/null 2>&1 || true

    echo "代理已停止 ✓"
}

case "${1:-}" in
    start) cmd_start ;;
    stop)  cmd_stop  ;;
    *) echo "用法: $0 {start|stop}" ;;
esac
