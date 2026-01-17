#!/bin/bash
# ============================================================================
# Script: configure_docker.sh
# Description: Configure Docker with Chinese registry mirrors and user permissions
# Logic: Creates daemon.json with multiple registry mirrors, adds user to
#        docker group, enables and restarts Docker service
# ============================================================================
# 脚本: configure_docker.sh
# 描述: 配置 Docker 中国镜像源和用户权限
# 逻辑: 创建包含多个镜像源的 daemon.json,将用户添加到 docker 组,
#        启用并重启 Docker 服务
# ============================================================================

#--> Configure Docker daemon --> 配置 Docker 守护进程
docker_conf() {
    local daemon_file="/etc/docker/daemon.json"
    
    #--> Stop Docker first --> 先停止 Docker
    sudo systemctl stop docker &>/dev/null
    
    #--> Create docker directory --> 创建 docker 目录
    sudo mkdir -p /etc/docker
    #--> Write daemon.json --> 写入 daemon.json
    sudo tee "$daemon_file" > /dev/null <<'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.1panel.live",
    "https://docker.m.ixdev.cn",
    "https://hub.rat.dev",
    "https://dockerproxy.net",
    "https://docker.hlmirror.com",
    "https://hub1.nat.tf",
    "https://hub3.nat.tf",
    "https://docker.m.daocloud.io",
    "https://docker.kejilion.pro",
    "https://hub.1panel.dev",
    "https://dockerproxy.cool",
    "https://proxy.vvvv.ee"
  ]
}
EOF
    
    #--> Add user to docker group --> 添加用户到 docker 组
    sudo usermod -aG docker "$USER" &>/dev/null
    
    #--> Reload and restart Docker --> 重载并重启 Docker
    sudo systemctl daemon-reload
    sudo systemctl enable --now docker &>/dev/null
    
    echo "✓ Docker configured"
    echo "⚠ Please logout and login again for group changes to take effect"
}
