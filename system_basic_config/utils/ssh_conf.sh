#!/bin/bash
# ============================================================================
# Script: gen_ssh.sh
# Description: Generate SSH key pair with specified encryption type
# Logic: Creates SSH directory, generates key pair (default ed25519), sets
#        proper permissions (700 for dir, 600 for private, 644 for public),
#        and displays the public key
# ============================================================================
# 脚本: gen_ssh.sh
# 描述: 生成指定加密类型的 SSH 密钥对
# 逻辑: 创建 SSH 目录，生成密钥对（默认 ed25519），设置正确的权限（目录 700，
#        私钥 600，公钥 644），并显示公钥
# ============================================================================

set -euo pipefail

#--> Generate SSH key --> 生成 SSH 密钥
ssh_conf() {
	local email=${1:-"19157521820@163.com"}
	local ssh_key_type=${2:-"ed25519"}
	local ssh_dir=${3:-"/data/.home/.ssh"}

	mkdir -p "$ssh_dir"
	local ssh_real_path=$(readlink -f "$ssh_dir")
	local ssh_key_path="$ssh_real_path/id_$ssh_key_type"

	#--> Generate key if not exists --> 如果不存在则生成密钥
	if [[ ! -f "$ssh_key_path" ]]; then
		ssh-keygen -t "$ssh_key_type" -C "$email" -f "$ssh_key_path" -N ""
		echo "✓ SSH key generated"
	else
		echo "✓ SSH key already exists"
	fi

	#--> Set permissions --> 设置权限
	chmod 700 "$ssh_real_path"
	chmod 600 "$ssh_real_path"/id_* 2>/dev/null || true
	chmod 644 "$ssh_real_path"/*.pub 2>/dev/null || true
	[[ -f "$ssh_real_path/config" ]] && chmod 600 "$ssh_real_path/config"

	# link to home
	local ssh_home_path="$HOME/.ssh"
	rm -rf "$ssh_home_path"
	ln -sf "$ssh_real_path" "$ssh_home_path"
}
