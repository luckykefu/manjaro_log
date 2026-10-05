#!/bin/bash

# ========== 1. 安装 tailscale ==========
install_tailscale() {
    # command -v 检查命令是否存在；不存在才执行官方安装脚本（输出可见）
    command -v tailscale || curl -fsSL https://tailscale.com/install.sh | sh
    # 用 -V 输出版本信息
    tailscale -V
}

# ========== 2. 启动 tailscaled 守护进程 ==========
start_tailscaled() {
    # || true 表示即使没进程可杀也不报错中断
    sudo killall tailscaled || true
    # nohup 后台运行，关掉终端也不退出；日志重定向到文件便于排查
    #   --tun=userspace-networking : 不创建真实 TUN 网卡（容器必须）
    #   --state=...               : 状态文件路径，保存登录信息，重启免重新登录
    #   --socks5-server=localhost:1055 : 本机 1055 端口开 SOCKS5 代理
    sudo nohup tailscaled --tun=userspace-networking \
        --state=/var/lib/tailscale/tailscaled.state \
        --socks5-server=localhost:1055 > /var/log/tailscaled.log 2>&1 &
}

# ========== 3. 上线 tailnet ==========
tailscale_up() {
    # tailscale 的 authkey（认证密钥），用于免交互式登录 tailnet
    local TS_AUTHKEY="tskey-auth-kntP2EjRL411CNTRL-GkpejtYkZuK27sersA9wuKB8VrfZeukjD"
    #   --socket=... : tailscaled 的本地 socket 路径（非 systemd 环境手动指定）
    #   up           : 启动并登录 tailnet
    #   --accept-routes : 接受 tailnet 其他节点广播的子网路由
    #   --accept-dns=false : 不接管系统 DNS（容器里改 DNS 通常没权限/没必要）
    #   --ssh        : 开启 Tailscale SSH，允许其他节点 SSH 进来
    #   --authkey=... : 用密钥完成认证，无需浏览器手动登录
    sudo tailscale --socket=/run/tailscale/tailscaled.sock up \
        --accept-routes --accept-dns=false \
        --ssh --authkey="${TS_AUTHKEY}"
    echo "done, ip: $(tailscale ip -4)"
}

# ========== 4. 配置 ssh ==========
configure_ssh() {
    # 确保 ~/.ssh 目录存在
    mkdir -p ~/.ssh
    # 写入 ssh 配置：
    #   ProxyCommand tailscale nc %h %p : 用 tailscale nc 建立到目标主机的连接
    #   StrictHostKeyChecking accept-new : 首次连接自动接受指纹，不交互询问
    cat >> ~/.ssh/config << 'EOF'
Host 100.*
    ProxyCommand tailscale nc %h %p
    StrictHostKeyChecking accept-new
EOF
}

# ========== 5. 拉取远程文件 ==========
fetch_agents_md() {
    # 已配置 ~/.ssh/config，直接用 scp 即可
    #   lkf@100.75.45.52:... : 远程用户@tailscale IP:文件路径
    #   . : 保存到当前目录
    scp lkf@100.75.45.52:/data/.manjaro/AGENTS.md .
}

# ========== 6. 安装并运行 opencode ==========
install_and_run_opencode() {
    # [ -x ... ] 判断文件存在且可执行；|| 表示不存在才执行安装
    [ -x ~/.opencode/bin/opencode ] || curl -fsSL https://opencode.ai/v2/install | bash
    # ~ 是当前用户家目录（/root 或 /home/xxx）
    ~/.opencode/bin/opencode
}

# ========== 主流程 ==========
install_tailscale
start_tailscaled
sleep 3    # 等 tailscaled 初始化完成，避免 socket 未就绪报错
tailscale_up
configure_ssh
fetch_agents_md
install_and_run_opencode
