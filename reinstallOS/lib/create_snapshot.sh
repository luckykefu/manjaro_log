snapshot_name=$1
sudo btrfs subvolume snapshot -r / /.snapshots/"$snapshot_name"
sudo btrfs subvolume snapshot -r /home /home/.snapshots/"$snapshot_name"
ls -a /.snapshots /home/.snapshots
