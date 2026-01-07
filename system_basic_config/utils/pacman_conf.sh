#!/bin/bash
pacman_conf() {
	local PACMAN_FILE=/etc/pacman.conf
	local options=("Color" "ILoveCandy" "ParallelDownloads = 16")

	for opt in "${options[@]}"; do
		local key=${opt%% *}
		# 删除旧配置并添加新配置
		sudo sed -i "/^#\?$key/d; /^\[options\]/a $opt" "$PACMAN_FILE"
	done

	echo "✓ pacman options configured"
}
