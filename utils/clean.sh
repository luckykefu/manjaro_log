#!/bin/bash

clean() {

	# 清理旧版本缓存
	sudo pacman -Sc --noconfirm || true

	# 清理所有缓存
	yes | sudo pacman -Scc 2>/dev/null || true

	# 清理AUR缓存
	yes | yay -Scc 2>/dev/null || true

	# 清理日志
	sudo journalctl --vacuum-time=7d || true
}
