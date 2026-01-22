#!/bin/bash
# ============================================================================

#--> Install Miniconda3 --> 安装 Miniconda3
miniconda3_conf() {
	local install_dir="${1:-/data/.path/.miniconda3}"

	#--> Check if already installed --> 检查是否已安装
	if [[ -f "$install_dir/bin/conda" ]]; then
		echo "✓ Miniconda3 already installed, skipping"
		return 0
	fi

	#--> Download --> 下载
	local save_path="$HOME/Downloads"
	cd "$save_path"
	local download_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
	local installer="Miniconda3-latest-Linux-x86_64.sh"
	aria2c -x 16 -s 16 "$download_url" -o "$installer"

	#--> Install --> 安装
	rm -rf "$install_dir"
	mkdir -p "$(dirname "$install_dir")"
	bash "$installer" -b -f -p "$install_dir"

	#--> Verify and configure --> 验证并配置
	conda_bin="$install_dir/bin/conda"

	if [[ -f "$conda_bin" ]]; then
		echo "✓ Miniconda3 installed successfully"
		"$conda_bin" init zsh
		"$conda_bin" config --set auto_activate_base false
		"$conda_bin" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
		"$conda_bin" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
		"$conda_bin" install jupyter ipykernel -y
		echo "✓ Miniconda3 configured!"
	else
		echo "❌ Miniconda3 installation failed"
		return 1
	fi
}
