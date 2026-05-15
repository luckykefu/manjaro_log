#!/bin/bash
# scripts/ssh-reverse-proxy.sh
# SSH 反向代理一键配置
#
# 入参:
#   $1 远程服务器IP (必填)
#   $2 本机密钥路径 (默认 ~/.ssh/id_ed25519)
#   $3 本地转发端口 (默认 2222)
# 返回:
#   0 隧道建立成功
#   1 配置失败
#
# ASCII图示处理逻辑:
# 1 -> ensure_local_key     检查/生成本机 SSH 密钥对
# 2 -> clean_known_hosts    清理远程服务器旧 host key
# 3 -> push_key_to_remote   推送本机公钥到远程服务器
# 4 -> ensure_remote_key    检查/生成远程服务器 SSH 密钥对
# 5 -> add_remote_key       将远程公钥加入本机 authorized_keys
# 6 -> start_tunnel         建立反向代理隧道
# 返回 -> 隧道建立成功/失败

ssh_reverse_proxy() {
    local func="ssh_reverse_proxy"
    local ip=${1:-}
    local key=${2:-"${HOME}/.ssh/id_ed25519"}
    local local_port=${3:-2222}
    local remote_user="root"
    local pid_file="/tmp/ssh-reverse-tunnel.pid"

    if [[ -z "${ip}" ]]; then
        echo "用法: ${func} <远程服务器IP> [密钥路径] [本地端口]"
        echo "示例: ${func} 202.182.112.91"
        return 1
    fi

    # 1. 检查/生成本机 SSH 密钥对
    echo "[1/6] 检查本机 SSH 密钥"
    if [[ ! -f "${key}" ]]; then
        echo "  生成本机 SSH 密钥: ${key}"
        ssh-keygen -t ed25519 -f "${key}" -N "" || return 1
    else
        echo "  本机 SSH 密钥已存在: ${key}"
    fi

    # 2. 清理远程服务器旧 host key
    echo "[2/6] 清理 ${ip} 旧 host key"
    ssh-keygen -R "${ip}" 2>/dev/null || true

    # 3. 推送本机公钥到远程服务器
    echo "[3/6] 推送本机公钥到 ${remote_user}@${ip}"
    ssh-copy-id -o StrictHostKeyChecking=accept-new \
        -i "${key}.pub" "${remote_user}@${ip}" || return 1

    # 4. 检查/生成远程服务器 SSH 密钥对
    echo "[4/6] 检查远程服务器 SSH 密钥"
    ssh "${remote_user}@${ip}" \
        "[[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''" \
        || return 1

    # 5. 将远程公钥加入本机 authorized_keys
    echo "[5/6] 添加远程公钥到本机 authorized_keys"
    local remote_pub
    remote_pub=$(ssh "${remote_user}@${ip}" "cat ~/.ssh/id_ed25519.pub") || return 1
    if ! grep -q "${remote_pub}" ~/.ssh/authorized_keys 2>/dev/null; then
        echo "${remote_pub}" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo "  远程公钥已添加"
    else
        echo "  远程公钥已存在，跳过"
    fi

    # 6. 建立反向代理隧道
    echo "[6/6] 建立反向代理隧道: localhost:${local_port} <- ${remote_user}@${ip}:${local_port}"
    if [[ -f "${pid_file}" ]]; then
        local old_pid
        old_pid=$(cat "${pid_file}")
        if kill -0 "${old_pid}" 2>/dev/null; then
            echo "  隧道已在运行 (PID: ${old_pid})"
            cat << EOF
====== SSH 反向代理配置完成 ======
远程操作命令:
  ssh -p ${local_port} ${USER}@localhost
  scp -P ${local_port} file ${USER}@localhost:/path/
EOF
            return 0
        fi
        rm -f "${pid_file}"
    fi

    ssh -N -R "${local_port}:localhost:22" "${remote_user}@${ip}" &
    local pid=$!
    echo "${pid}" > "${pid_file}"
    echo "  隧道已建立 (PID: ${pid})"

    cat << EOF
====== SSH 反向代理配置完成 ======
远程操作命令:
  ssh -p ${local_port} ${USER}@localhost
  scp -P ${local_port} file ${USER}@localhost:/path/
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ssh_reverse_proxy "$@"
fi
