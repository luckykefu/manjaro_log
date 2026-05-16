# ============================================================
# lib.sh — Runner: source step files, orchestrate setup+tunnel
# ============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

G='\033[0;32m'; Y='\033[0;33m'; R='\033[0;31m'; N='\033[0m'
sinfo()  { echo -e "${G}$*${N}"; }
swarn()  { echo -e "${Y}$*${N}" >&2; }
serror() { echo -e "${R}$*${N}" >&2; }

source "$DIR/lib/setup.sh"
source "$DIR/lib/tunnel.sh"

lib_main() {
  local ip key local_port action
  ip=""
  key="${HOME}/.ssh/id_ed25519"
  local_port=2223
  action="all"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ip|-i)         ip="$2";        shift 2 ;;
      --key|-k)        key="$2";       shift 2 ;;
      --port|-p)       local_port="$2"; shift 2 ;;
      --setup)         action="setup";  shift ;;
      --start)         action="start";  shift ;;
      --stop)          action="stop";   shift ;;
      --status)        action="status"; shift ;;
      --help|-h)       sinfo "Usage: main.sh --ip IP [--key PATH] [--port N] [--setup|--start|--stop|--status]"; exit 0 ;;
      *) serror "unknown: $1"; exit 1 ;;
    esac
  done

  [[ -z "$ip" && "$action" != "stop" && "$action" != "status" ]] && serror "--ip required" && exit 1

  case "$action" in
    setup)  setup "$ip" "$key" ;;
    start)  tunnel_start "$ip" "$local_port" ;;
    stop)   tunnel_stop ;;
    status) tunnel_status ;;
    all)    setup "$ip" "$key" && tunnel_start "$ip" "$local_port" ;;
  esac
}
