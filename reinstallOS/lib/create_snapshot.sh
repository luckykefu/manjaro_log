snapshot_name=$1
sudo btrfs subvolume snapshot -r / /.snapshots/"$snapshot_name"
ls -a /.snapshots
