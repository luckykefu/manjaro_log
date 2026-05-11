## LUKS 加密 USB + GPG 密钥完整教程

将普通 USB 制作成安全密钥存储设备


### 步骤 1：确认 USB 设备


```bash
%%bash
## 查看所有存储设备
lsblk

## 确认 USB 设备（通常是 /dev/sda 或 /dev/sdb）
## ⚠️ 警告：接下来的操作会擦除该设备所有数据！
```

### 步骤 2：卸载 USB（如果已挂载）


```bash
%%bash
## 卸载所有分区
sudo umount /dev/sda* 2>/dev/null || true

## 验证未挂载
mount | grep sda || true
```

### 步骤 3：擦除现有分区表（可选）


```bash
%%bash
## 擦除分区表和文件系统签名
sudo wipefs -a /dev/sda

## 验证
sudo wipefs -n /dev/sda
```

### 步骤 4：LUKS 加密整个 USB


```bash
%%bash
## LUKS 格式化（需要输入 YES 确认）
sudo cryptsetup luksFormat /dev/sda

## 提示：
## 1. 输入：YES（必须大写）
## 2. 输入密码（至少 8 位，建议 16 位以上）
## 3. 再次输入密码确认
```

### 步骤 5：打开加密设备


```bash
%%bash
## 打开 LUKS 加密设备
sudo cryptsetup open /dev/sda secure_usb

## 输入刚才设置的密码
## 成功后会在 /dev/mapper/ 下创建 secure_usb 设备
```

```bash

%%bash
## 验证
ls -l /dev/mapper/secure_usb
```

### 步骤 6：格式化并设置标签


```bash
%%bash
## 格式化为  文件系统并设置标签
sudo mkfs.btrfs -L SecureUSB /dev/mapper/secure_usb

## 参数说明：
## -L SecureUSB：设置卷标为 SecureUSB
```

### 步骤 7：挂载 USB


```bash
%%bash
## 创建挂载点
sudo mkdir -p /mnt/secure_usb

## 挂载
sudo mount /dev/mapper/secure_usb /mnt/secure_usb

## 验证挂载
df -h | grep secure_usb
```

## GPG 密钥生成与导出


```bash
%%bash
## 1. 查看现有密钥
gpg --list-secret-keys

gpg --delete-secret-and-public-key kefu1820@gmail.com

## 4. 清理信任数据库（可选）
rm -rf ~/.gnupg/trustdb.gpg
gpg --update-trustdb
```

### 步骤 8：导出 GPG 密钥到 USB


```bash
%%bash
./find_and_run.sh gpg_conf.sh
```

```bash
%%bash
## 设置邮箱
EMAIL="kefu1820@gmail.com"

## 导出私钥（最重要！）
gpg --armor --export-secret-keys $EMAIL | sudo tee /mnt/secure_usb/gpg-private.key > /dev/null

## 导出公钥
gpg --armor --export $EMAIL | sudo tee /mnt/secure_usb/gpg-public.key > /dev/null

## 导出信任数据库
gpg --export-ownertrust | sudo tee /mnt/secure_usb/gpg-trust.txt > /dev/null

## 导出子密钥（可选）
gpg --armor --export-secret-subkeys $EMAIL | sudo tee /mnt/secure_usb/gpg-subkeys.key > /dev/null
```

### 步骤 9：生成撤销证书


```bash
%%bash
EMAIL="kefu1820@gmail.com" && gpg --output revoke.asc --gen-revoke $EMAIL

## y
## 选择原因：
## 1 = 密钥已泄露
## 2 = 密钥已被替换
## 3 = 密钥不再使用
## description;

## y
## 输入Gpg密码
```

```bash
%%bash

## 移动到 USB
sudo mv revoke.asc /mnt/secure_usb/
```

### 步骤 10：创建 README 文件


```bash
%%bash
## 创建说明文件
sudo tee /mnt/secure_usb/README.txt > /dev/null <<EOF
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

cat /mnt/secure_usb/README.txt
```

### 步骤 11：设置文件权限


```bash
%%bash
## 私钥文件设为只读（600）
sudo chmod 600 /mnt/secure_usb/gpg-*.key
sudo chmod 600 /mnt/secure_usb/revoke.asc

## 公开文件设为可读（644）
sudo chmod 644 /mnt/secure_usb/gpg-public.key
sudo chmod 644 /mnt/secure_usb/*.txt

## 验证权限
ls -lh /mnt/secure_usb/
```

### 步骤 12：卸载并关闭加密设备


```bash
%%bash
## 同步数据到磁盘
sync

## 卸载
sudo umount /mnt/secure_usb

## 关闭加密设备
sudo cryptsetup close secure_usb

## 验证已关闭
ls /dev/mapper/ | grep secure_usb || true
```

### 使用安全 USB

#### 挂载 USB


```bash
%%bash
## 1. 打开加密设备
sudo cryptsetup open /dev/sda secure_usb
## 输入密码

## 2. 挂载
sudo mkdir -p /mnt/secure_usb
sudo mount /dev/mapper/secure_usb /mnt/secure_usb

## 3. 查看文件
ls -lh /mnt/secure_usb/
```

#### 恢复 GPG 密钥到新电脑


```bash
%%bash
## 导入私钥
gpg --import /mnt/secure_usb/gpg-private.key

## 导入信任数据库
gpg --import-ownertrust /mnt/secure_usb/gpg-trust.txt

## 验证
gpg --list-secret-keys
```

```bash
%%bash
## 加密文件
gpg -e -r kefu1820@gmail.com file.txt

## 解密文件
gpg -d file.txt.gpg

## 签名文件
gpg --sign file.txt
```

#### 卸载 USB


```bash
%%bash
## 同步
sync

## 卸载
sudo umount /mnt/secure_usb

## 关闭加密
sudo cryptsetup close secure_usb
```

### 一键脚本


```python
%bash
./find_and_run.sh create_secure_usb.sh
```

### 安全建议

#### 密码强度

```
✅ 至少 16 位
✅ 包含大小写字母、数字、符号
✅ 不使用字典单词
✅ 使用密码管理器生成
```

#### 备份策略

```
✅ 制作 2-3 个相同的安全 USB
✅ 分别存放在不同安全位置
✅ 定期验证备份可用性
✅ 更新密钥后同步所有备份
```

#### 使用注意

```
✅ 使用后立即卸载
✅ 不要在不信任的电脑上使用
✅ 定期更换密码
✅ 妥善保管撤销证书
```

