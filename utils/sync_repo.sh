#!/bin/bash
sync_repo() {
	local d=${1:-.}
	cd "$d" || return 1

	git add -A

	# 检查是否有变更
	if git diff --cached --quiet; then
		echo "✓ 无变更，跳过提交"
		return 0
	fi

	git commit -m "update $(date -Iseconds)" && git push
}
