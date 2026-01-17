#!/bin/bash
archlinuxcn_conf() {
	local PACMAN_FILE=/etc/pacman.conf
	local Server=${1:-"https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch"}

	# 添加 [archlinuxcn] 配置
	if ! grep -q "^\[archlinuxcn\]" "$PACMAN_FILE"; then
		echo -e "\n[archlinuxcn]\nServer = $Server" | sudo tee -a "$PACMAN_FILE" >/dev/null
	else
		# 删除 [archlinuxcn] 段中所有 Server 行
		sudo sed -i "/^\[archlinuxcn\]/,/^\[/{/^Server/d}" "$PACMAN_FILE"
		# 在 [archlinuxcn] 后添加新 Server
		sudo sed -i "/^\[archlinuxcn\]/a Server = $Server" "$PACMAN_FILE"
	fi

	echo "✓ archlinuxcn configured: $Server"
}
