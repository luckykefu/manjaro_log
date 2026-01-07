#!/bin/bash

set -euo pipefail
#--> Configure sudo without password --> 配置 sudo 免密码
sudo_nopassword() {
	echo -e "configuring sudo nopassword...\n"
	# 1. get user
	local user="${SUDO_USER:-$(logname)}"
	[[ -z "$user" ]] && {
		echo "❌ Cannot determine user"
		return 1
	}

	local sudoers_file="/etc/sudoers.d/${user}_nopasswd"
	echo "Configuring sudo without password for: $user"
	# 创建配置文件
	echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" >/dev/null
	# 验证语法
	if ! sudo visudo -c -f "$sudoers_file" >/dev/null 2>&1; then
		sudo rm -f "$sudoers_file"
		echo "❌ Invalid sudoers syntax"
		return 1
	fi

	# 设置权限
	sudo chmod 440 "$sudoers_file"
	echo "✓ Sudo no password configured for $user"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && sudo_nopassword
