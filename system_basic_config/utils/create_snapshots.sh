#!/bin/bash
create_snapshots() {
	local dev=${1:-/data}
	local snapshot_dir="$dev/.snapshots"
	
	sudo mkdir -p "$snapshot_dir"
	
	local snapshot_name="$snapshot_dir/data_$(date +%Y%m%d)"
	
	if [[ -d "$snapshot_name" ]]; then
		echo "  ✓ Snapshot already exists: $snapshot_name"
	else
		sudo btrfs subvolume snapshot -r "$dev" "$snapshot_name"
		echo "  ✓ Created snapshot: $snapshot_name"
	fi
	
	echo "Current snapshots:"
	sudo btrfs subvolume list "$dev"
}
