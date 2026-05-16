# ============================================================
# lib.sh — Runner: sources step files, orchestrates 4-step flow
# ============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

G='\033[0;32m'; Y='\033[0;33m'; R='\033[0;31m'; N='\033[0m'
sinfo()  { echo -e "${G}$*${N}"; }
swarn()  { echo -e "${Y}$*${N}" >&2; }
serror() { echo -e "${R}$*${N}" >&2; }

source "$DIR/lib/install.sh"
source "$DIR/lib/parse.sh"
source "$DIR/lib/config.sh"
source "$DIR/lib/start.sh"
source "$DIR/lib/check.sh"

lib_main() {
  local subscribe_link output_dir nameserver proxy skip_start auto_install
  output_dir="${HOME}/.config/mihomo"
  nameserver=""
  proxy=""
  skip_start=false
  auto_install=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --subscribe-link) subscribe_link="$2"; shift 2 ;;
      --output-dir)    output_dir="$2";     shift 2 ;;
      --nameserver)    nameserver="$2";     shift 2 ;;
      --proxy)         proxy="$2";          shift 2 ;;
      --skip-start)    skip_start=true;      shift ;;
      --install)       auto_install=true;    shift ;;
      --help|-h)       sinfo "Usage: main.sh [--install] --subscribe-link URL [--nameserver IP] [--proxy URL] [--output-dir DIR] [--skip-start]"; exit 0 ;;
      *) serror "unknown option: $1"; exit 1 ;;
    esac
  done

  [[ "$auto_install" == "true" ]] && { install || exit 1; }

  [[ -z "${subscribe_link:-}" ]] && serror "--subscribe-link is required" && exit 1

  run_parse "$subscribe_link" "$output_dir" "$nameserver" "$proxy" || { serror "parse failed"; exit 1; }

  if [[ "$skip_start" == "false" ]]; then
    start "$output_dir"
    check
  else
    sinfo "skip-start enabled"
    sinfo "  start manually: nohup mihomo -d $output_dir > /tmp/mihomo.log 2>&1 & disown"
  fi

  sinfo "done"
}
