#!/bin/bash
DIRS=(
    /run/media/manjaro/data/.cryptomator
    /run/media/manjaro/data/.manjaro
)
for DIR in "${DIRS[@]}"; do
  if [[ -d "$DIR/.git" ]]; then
    echo "=== 正在处理: $DIR ==="
    cd "$DIR" && git add -A && git diff --cached --quiet || git commit -m "$(date '+%Y-%m-%d')" && git push
  else
    echo "=== 跳过: $DIR (不是 git 仓库或未挂载) ==="
  fi
done
