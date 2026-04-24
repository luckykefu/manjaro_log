#!/bin/bash
# 配置 sudo 免密码
set -euo pipefail

sudo_nopassword() {
	# 获取用户名
	local user="${SUDO_USER:-$(logname)}"
	[[ -z "$user" ]] && { echo "❌ Cannot determine user"; return 1; }

	# 创建 sudoers 配置文件
	local sudoers_file="/etc/sudoers.d/${user}_nopasswd"
	echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" >/dev/null

	# 验证语法并设置权限
	if ! sudo visudo -c -f "$sudoers_file" >/dev/null 2>&1; then
		sudo rm -f "$sudoers_file"
		echo "❌ Invalid sudoers syntax"
		return 1
	fi

	sudo chmod 440 "$sudoers_file"
	echo "✓ Sudo no password configured for $user"
}

# 直接执行时自动调用
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && sudo_nopassword
