#!/bin/bash
gpg_conf() {
	local pswd name email gd
	name=${1:-"kefu"}
	email=${2:-"kefu1820@gmail.com"}
	gd=${3:-${GPG_DIR:-"$HOME/.gnupg"}}

	# 检查密钥是否已存在
	if gpg --list-keys "$email" &>/dev/null; then
		echo "✓ GPG key already exists for $email"
		return 0
	fi

	# 交互式输入密码
	read -sp "Enter GPG passphrase: " pswd
	echo

	# 创建 GPG 目录和子目录
	chmod 700 "$gd"

	# 生成密钥配置
	local tmp=$(mktemp)
	cat >"$tmp" <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $name
Name-Email: $email
Expire-Date: 3y
Passphrase: $pswd
%commit
%echo done
EOF

	# 生成密钥
	gpg --batch --generate-key "$tmp"
	rm -f "$tmp"

	# 修复权限
	find "$gd" -type f -exec chmod 600 {} \;

	echo "✓ GPG key generated for $email"
	gpg --list-keys "$email"
}
