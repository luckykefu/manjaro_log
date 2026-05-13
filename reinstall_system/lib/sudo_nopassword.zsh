# sudo_nopassword.sh — 配置免密码 sudo
# DOC:
#   1. 参数解析（默认当前用户）
#   2. 校验：sudo 可用 → 用户名非空 → 用户存在 → 格式合法
#   3. 写入 /etc/sudoers.d/$USER NOPASSWD 条目
#   4. 设置 0440 权限
# 用法: sudo_nopassword.sh [user]

sudo_nopassword() {
    # 1. 参数解析：默认从 SUDO_USER → whoami
    local user="${1:-${SUDO_USER:-$(whoami)}}"

    # 2. 校验
    [[ -z "$user" ]] && return 1
    id "$user" &>/dev/null || return 1
    [[ "$user" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]] || return 1

    local sudoers_file="/etc/sudoers.d/$user"

    # 3. 写入 NOPASSWD 条目
    echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null || return 1

    # 4. 设置安全权限
    sudo chmod 0440 "$sudoers_file" || return 1

    echo "已为用户 $user 配置免密码 sudo"
}
