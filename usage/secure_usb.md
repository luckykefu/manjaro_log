## LUKS 加密 USB + GPG 密钥完整教程

```bash
## 查看所有存储设备
lsblk
## 卸载所有分区
sudo umount /dev/sdd* 2>/dev/null || true

## 验证未挂载
mount | grep sdd || true
## 擦除分区表和文件系统签名
sudo wipefs -a /dev/sdd
sudo wipefs -n /dev/sdd
## LUKS 格式化（需要输入 YES 确认）
sudo cryptsetup luksFormat /dev/sdd
## 提示：
## 1. 输入：YES（必须大写）
## 2. 输入密码（至少 8 位，建议 16 位以上）
## 3. 再次输入密码确认

## 打开 LUKS 加密设备
sudo cryptsetup open /dev/sdd LuksUSB
## 输入刚才设置的密码
## 成功后会在 /dev/mapper/ 下创建 LuksUSB 设备
## 验证
ls -l /dev/mapper/LuksUSB

## 格式化为  文件系统并设置标签
sudo mkfs.btrfs -L LuksUSB /dev/mapper/LuksUSB

## 创建挂载点
sudo mkdir -p /mnt/LuksUSB

## 挂载
sudo mount /dev/mapper/LuksUSB /mnt/LuksUSB

## 验证挂载
df -h | grep LuksUSB

## GPG 密钥生成与导出
## 1. 查看现有密钥
gpg --list-secret-keys

gpg --delete-secret-and-public-key kefu1820@gmail.com

## 4. 清理信任数据库（可选）
rm -rf ~/.gnupg/trustdb.gpg
gpg --update-trustdb
### 步骤 8：导出 GPG 密钥到 USB
./find_and_run.sh gpg_conf.sh
## 设置邮箱
EMAIL="kefu1820@gmail.com"

## 导出私钥（最重要！）
gpg --armor --export-secret-keys $EMAIL | sudo tee /mnt/LuksUSB/gpg-private.key > /dev/null

## 导出公钥
gpg --armor --export $EMAIL | sudo tee /mnt/LuksUSB/gpg-public.key > /dev/null

## 导出信任数据库
gpg --export-ownertrust | sudo tee /mnt/LuksUSB/gpg-trust.txt > /dev/null

## 导出子密钥（可选）
gpg --armor --export-secret-subkeys $EMAIL | sudo tee /mnt/LuksUSB/gpg-subkeys.key > /dev/null

### 步骤 9：生成撤销证书
EMAIL="kefu1820@gmail.com" && gpg --output revoke.asc --gen-revoke $EMAIL

## y
## 选择原因：
## 1 = 密钥已泄露
## 2 = 密钥已被替换
## 3 = 密钥不再使用
## description;

## y
## 输入Gpg密码

## 移动到 USB
sudo mv revoke.asc /mnt/LuksUSB/

### 步骤 10：创建 README 文件

## 创建说明文件
sudo tee /mnt/LuksUSB/README.txt > /dev/null <<EOF
GPG 安全密钥 USB
================
创建时间: $(date)
邮箱: kefu1820@gmail.com

文件说明:
---------
gpg-private.key  - 私钥（务必保密！）
gpg-public.key   - 公钥（可公开）
gpg-subkeys.key  - 子密钥
gpg-trust.txt    - 信任数据库
revoke.asc       - 撤销证书（密钥泄露时使用）

恢复密钥:
---------
1. 导入私钥:
   gpg --import gpg-private.key

2. 导入信任:
   gpg --import-ownertrust gpg-trust.txt

3. 验证:
   gpg --list-secret-keys

撤销密钥:
---------
gpg --import revoke.asc
gpg --keyserver keys.openpgp.org --send-keys KEY_ID

安全提示:
---------
- 妥善保管此 USB，不要丢失
- 不要将私钥上传到云端
- 定期备份到另一个安全位置
- 密码至少 16 位，包含大小写字母、数字、符号
EOF

cat /mnt/LuksUSB/README.txt

### 步骤 11：设置文件权限
## 私钥文件设为只读（600）
sudo chmod 600 /mnt/LuksUSB/gpg-*.key
sudo chmod 600 /mnt/LuksUSB/revoke.asc

## 公开文件设为可读（644）
sudo chmod 644 /mnt/LuksUSB/gpg-public.key
sudo chmod 644 /mnt/LuksUSB/*.txt

## 验证权限
ls -lh /mnt/LuksUSB/

### 步骤 12：卸载并关闭加密设备

## 同步数据到磁盘
sync

## 卸载
sudo umount /mnt/LuksUSB

## 关闭加密设备
sudo cryptsetup close LuksUSB

## 验证已关闭
ls /dev/mapper/ | grep LuksUSB || true

### 使用安全 USB

#### 挂载 USB
## 1. 打开加密设备
sudo cryptsetup open /dev/sdd LuksUSB
## 输入密码

## 2. 挂载
sudo mkdir -p /mnt/LuksUSB
sudo mount /dev/mapper/LuksUSB /mnt/LuksUSB

## 3. 查看文件
ls -lh /mnt/LuksUSB/

#### 恢复 GPG 密钥到新电脑
## 导入私钥
gpg --import /mnt/LuksUSB/gpg-private.key

## 导入信任数据库
gpg --import-ownertrust /mnt/LuksUSB/gpg-trust.txt

## 验证
gpg --list-secret-keys
## 加密文件
gpg -e -r kefu1820@gmail.com file.txt

## 解密文件
gpg -d file.txt.gpg

## 签名文件
gpg --sign file.txt
#### 卸载 USB

## 同步
sync

## 卸载
sudo umount /mnt/LuksUSB

## 关闭加密
sudo cryptsetup close LuksUSB
```
