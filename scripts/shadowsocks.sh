shadowsocks() {
    local ip="${1:-}" port="${2:-1080}"
    [[ -z "$ip" ]] && { echo "error: server IP required" >&2; return 1; }
    local cfg_dir="$HOME/.config/shadowsocks"; mkdir -p "$cfg_dir"
    local tmp; tmp=$(mktemp)
    scp -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 "root@${ip}:/etc/shadowsocks-rust/${ip}.json" "$tmp" 2>/dev/null || { echo "error: failed to fetch config from $ip" >&2; rm -f "$tmp"; return 1; }
    python3 -c "
import json
with open('$tmp') as f:
    cfg = json.load(f)
cfg.pop('mode', None)
cfg['server'] = '$ip'
cfg['local_address'] = '0.0.0.0'
cfg['local_port'] = $port
with open('$cfg_dir/config.json', 'w') as f:
    json.dump(cfg, f, indent=2)
" 2>/dev/null && rm -f "$tmp"
    sudo fuser -k "${port}/tcp" 2>/dev/null || true
    pkill -f sslocal 2>/dev/null || true
    nohup sslocal -c "$cfg_dir/config.json" > "$cfg_dir/ss.log" 2>&1 &
    sleep 2
    ss -tlnp 2>/dev/null | grep -q ":$port " && echo "sslocal listening on port $port" || echo "warning: sslocal may not be listening" >&2
}
