#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ 符号链接工具 ]>>>>>>>>>>>>>>>
"""

import os
from pathlib import Path


def create_symlink(src: str, tgt: str, force: bool = False) -> bool:
    """创建符号链接
    :params:
        :src: 源文件/目录路径
        :tgt: 目标链接路径
        :force: 是否强制覆盖已存在的链接
    :return: 是否成功
    """
    print(f"DEBUG: {src=}, {tgt=}, {force=}")
    
    src_path = Path(src).expanduser().resolve()
    tgt_path = Path(tgt).expanduser()
    
    if not src_path.exists():
        print(f"ERROR: 源路径不存在: {src_path}")
        return False
    
    if tgt_path.exists() or tgt_path.is_symlink():
        if force:
            print(f"INFO: 删除已存在的目标: {tgt_path}")
            tgt_path.unlink()
        else:
            print(f"ERROR: 目标已存在: {tgt_path}")
            return False
    
    try:
        os.symlink(src_path, tgt_path)
        print(f"INFO: 创建链接成功: {tgt_path} -> {src_path}")
        return True
    except Exception as e:
        print(f"ERROR: 创建链接失败: {e}")
        return False


if __name__ == "__main__":
    create_symlink("/data/.home/.aws/amazonq", ".amazonq", force=True)
    create_symlink("/data/.manjaro", ".manjaro")