name="${1:-kefu}"
email="${2:-19157521820@163.com}"
git config --global user.name "$name"
git config --global user.email "$email"
git config --global init.defaultBranch main
git config --global credential.helper libsecret
echo "git configured"
