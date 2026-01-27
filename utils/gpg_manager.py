#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ GPG 密钥管理工具 ]>>>>>>>>>>>>>>>
"""

import subprocess
import tempfile
from pathlib import Path
from getpass import getpass
try:
    from config import logger
except ImportError:
    from .config import logger


class GPGManager:
    """GPG 密钥管理器"""
    
    @staticmethod
    def generate_key(name: str = "kefu", email: str = "kefu1820@gmail.com", gpg_dir: str | None = None):
        """生成 GPG 密钥
        :params:
            :name: 用户名
            :email: 邮箱
            :gpg_dir: GPG 目录路径
        :return: 是否成功
        """
        logger.debug(f"{name=}, {email=}, {gpg_dir=}")
        
        gpg_dir = Path(gpg_dir or Path.home() / ".gnupg")
        
        # 检查密钥是否已存在
        result = subprocess.run(
            ["gpg", "--list-keys", email],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            logger.info(f"✓ GPG key already exists for {email}")
            return True
        
        # 获取密码
        passphrase = getpass("Enter GPG passphrase: ")
        
        # 设置目录权限
        gpg_dir.mkdir(parents=True, exist_ok=True)
        gpg_dir.chmod(0o700)
        
        # 创建临时配置文件
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as tmp:
            tmp.write(f"""%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: {name}
Name-Email: {email}
Expire-Date: 3y
Passphrase: {passphrase}
%commit
%echo done
""")
            tmp_path = tmp.name
        
        try:
            # 生成密钥
            subprocess.run(
                ["gpg", "--batch", "--generate-key", tmp_path],
                check=True
            )
            
            # 设置文件权限
            for file in gpg_dir.rglob("*"):
                if file.is_file():
                    file.chmod(0o600)
            
            logger.info(f"✓ GPG key generated for {email}")
            
            # 列出密钥
            subprocess.run(["gpg", "--list-keys", email])
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"生成 GPG 密钥失败: {e}")
            return False
        finally:
            Path(tmp_path).unlink(missing_ok=True)


if __name__ == "__main__":
    # >>>>>>>>>>>>>>>>>>>>[ 使用示例 ]>>>>>>>>>>>>>>>
    GPGManager.generate_key("kefu", "kefu1820@gmail.com")
