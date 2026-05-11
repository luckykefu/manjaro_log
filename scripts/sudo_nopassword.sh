#!/usr/bin/env bash
set -euo pipefail
target_user="${1:-${SUDO_USER:-$(whoami)}}"
echo "$target_user ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$target_user" > /dev/null
sudo chmod 440 "/etc/sudoers.d/$target_user"
echo "Passwordless sudo configured for user: $target_user"
