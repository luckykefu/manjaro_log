create_snapshot() {
    local mnt="${1:-/}"
    local snapshot_name="${2:-update_system}"
    
    # >>>>>>>>>>>>>>>>>>>>处理路径拼接>>>>>>>>>>>>>>>
    [[ "$mnt" == "/" ]] && mnt=""
    local snapshot_dir="${mnt}/.snapshots"
    sudo mkdir -p "$snapshot_dir"
    
    # >>>>>>>>>>>>>>>>>>>>创建快照>>>>>>>>>>>>>>>
    local snapshot_path="$snapshot_dir/$snapshot_name"
    if [[ -d "$snapshot_path" ]]; then
        echo "  ✓ Snapshot already exists: $snapshot_path"
    else
        sudo btrfs subvolume snapshot -r "${mnt:-/}" "$snapshot_path"
        echo "  ✓ Created snapshot: $snapshot_path"
    fi
}