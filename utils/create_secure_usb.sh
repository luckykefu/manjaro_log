#!/bin/bash
set -euo pipefail

DEVICE=${1:-/dev/sda}
EMAIL="kefu1820@gmail.com"
MOUNT="/mnt/secure_usb"

# 显示设备并确认
lsblk
echo "⚠️  警告：将擦除 $DEVICE 所有数据！"
read -p "继续？(y/n): " -r confirm
[[ "$confirm" != "y" ]] && exit 1

# 准备设备
sudo umount "${DEVICE}"* 2>/dev/null || true
echo "擦除分区表..."
sudo wipefs -a "$DEVICE"

# LUKS 加密
echo "LUKS 格式化（输入 YES 和密码）..."
sudo cryptsetup luksFormat "$DEVICE"

echo "打开加密设备..."
sudo cryptsetup open "$DEVICE" secure_usb

# 格式化和挂载
echo "格式化为 Btrfs..."
sudo mkfs.btrfs -L SecureUSB /dev/mapper/secure_usb

sudo mkdir -p "$MOUNT"
sudo mount /dev/mapper/secure_usb "$MOUNT"

# GPG 密钥操作
echo "生成 GPG 密钥..."
./find_and_run.sh gpg_conf.sh

echo "导出 GPG 密钥..."
gpg --armor --export-secret-keys "$EMAIL" | sudo tee "$MOUNT/gpg-private.key" >/dev/null
gpg --armor --export "$EMAIL" | sudo tee "$MOUNT/gpg-public.key" >/dev/null
gpg --export-ownertrust | sudo tee "$MOUNT/gpg-trust.txt" >/dev/null
gpg --armor --export-secret-subkeys "$EMAIL" | sudo tee "$MOUNT/gpg-subkeys.key" >/dev/null

echo "生成撤销证书（选择原因并输入密码）..."
gpg --gen-revoke "$EMAIL" | sudo tee "$MOUNT/revoke.asc" >/dev/null

# 创建 README
sudo tee "$MOUNT/README.txt" >/dev/null <<EOF
GPG 安全密钥 USB
================
创建时间: $(date)
邮箱: $EMAIL

文件说明:
  gpg-private.key  - 私钥（务必保密！）
  gpg-public.key   - 公钥
  gpg-subkeys.key  - 子密钥
  gpg-trust.txt    - 信任数据库
  revoke.asc       - 撤销证书

恢复密钥:
  gpg --import gpg-private.key
  gpg --import-ownertrust gpg-trust.txt
  gpg --list-secret-keys

撤销密钥:
  gpg --import revoke.asc
  gpg --keyserver keys.openpgp.org --send-keys KEY_ID

安全提示:
  - 妥善保管此 USB
  - 不要上传私钥到云端
  - 定期备份
  - 使用强密码（16+ 位）
EOF

# 设置权限
echo "设置权限..."
sudo chmod 600 "$MOUNT"/gpg-*.key "$MOUNT/revoke.asc"
sudo chmod 644 "$MOUNT/gpg-public.key" "$MOUNT"/*.txt

# 清理
echo "卸载..."
sync
sudo umount "$MOUNT"
sudo cryptsetup close secure_usb

[[ ! -e /dev/mapper/secure_usb ]] && echo "✓ 完成！" || echo "⚠️  设备未正确关闭"
echo "请拔出 USB 并安全移除"
