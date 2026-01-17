#!/bin/bash
install_dolphin_vscode() {
	local dest_file="$HOME/.local/share/kio/servicemenus/openVSCode.desktop"

	# 检查是否已安装
	if [[ -f "$dest_file" ]]; then
		echo "  ✓ Dolphin VSCode menu already installed, skipping"
		return 0
	fi

	local temp_dir="/tmp/dolphin-vscode-$$"

	mkdir -p "$(dirname "$dest_file")"
	if git clone git@github.com:Merrit/kde-dolphin-open-vscode.git "$temp_dir" &>/dev/null; then
		mv "$temp_dir/openVSCode.desktop" "$dest_file"
		chmod +x "$dest_file"
		rm -rf "$temp_dir"
		echo "  ✓ Dolphin VSCode menu installed"
	else
		echo "  ✗ Failed to install Dolphin VSCode menu"
		return 1
	fi
}
