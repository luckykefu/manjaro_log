#!/usr/bin/env bash
set -euo pipefail
# autostart.sh — 搜索 .desktop 文件并创建开机自启符号链接
# 用法: ./autostart.sh <app1> [app2 ...]
SEARCH_DIRS=(
  "/usr/share/applications"
  "/usr/local/share/applications"
  "$HOME/.local/share/applications"
)
normalize() {
  local s="$1"
  s="${s,,}"
  s="${s// /-}"
  echo "$s"
}
score_match() {
  local norm_query="$1" norm_name="$2"
  [[ "$norm_name" == "$norm_query" ]]          && return 100
  [[ "$norm_name" == "$norm_query"* ]]          && return 80
  [[ "$norm_query" == "$norm_name"* ]]          && return 60
  [[ "$norm_name" == *"$norm_query"* ]]         && return 40
  return 0
}
find_desktop() {
  local app="$1" norm_app
  norm_app=$(normalize "$app")
  local best_file="" best_name="" best_score=0 dir f name norm_name score
  for dir in "${SEARCH_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' f; do
      name="$(basename "$f" .desktop)"
      norm_name=$(normalize "$name")
      score_match "$norm_app" "$norm_name"; score=$?
      [[ "$score" -gt 0 ]] || continue
      if [[ "$score" -gt "$best_score" ]] || \
         { [[ "$score" -eq "$best_score" ]] && [[ "${#name}" -lt "${#best_name}" ]]; }; then
        best_score=$score
        best_name="$name"
        best_file="$f"
      fi
    done < <(find "$dir" -maxdepth 1 -type f -name "*.desktop" -print0 2>/dev/null)
  done
  [[ -n "$best_file" ]] && echo "$best_file"
}
create_autostart() {
  local app="$1" desktop
  desktop=$(find_desktop "$app") || true
  [[ -z "$desktop" ]] && { echo "x $app: no matching .desktop found"; return 1; }
  local autostart_dir="$HOME/.config/autostart"
  mkdir -p "$autostart_dir"
  local target="$autostart_dir/$(basename "$desktop")"
  ln -sf "$desktop" "$target"
  echo "v $app: $(basename "$desktop")  ->  $target"
}
main() {
  [[ $# -eq 0 ]] && { echo "Usage: $(basename "$0") <app1> [app2 ...]"; exit 1; }
  local app rc=0
  for app in "$@"; do
    create_autostart "$app" || rc=1
  done
  return "$rc"
}
main "$@"
