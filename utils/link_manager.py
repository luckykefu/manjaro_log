#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ 符号链接工具 ]>>>>>>>>>>>>>>>
"""

import os
import shutil
from pathlib import Path
from typing import Any
try:
    from config import logger
except ImportError:
    from .config import logger


class LinkManager:
    """符号链接管理器"""
    
    @staticmethod
    def create(src: str, tgt: str, force: bool = False) -> bool:
        """创建符号链接
        :params:
            :src: 源文件/目录路径
            :tgt: 目标链接路径
            :force: 是否强制覆盖已存在的链接
        :return: 是否成功
        """
        logger.debug(f"{src=}, {tgt=}, {force=}")
        
        src_path = Path(src).expanduser().resolve()
        tgt_path = Path(tgt).expanduser()
        
        if not src_path.exists():
            logger.error(f"源路径不存在: {src_path}")
            return False
        
        if tgt_path.exists() or tgt_path.is_symlink():
            if force:
                if tgt_path.is_dir() and not tgt_path.is_symlink():
                    shutil.rmtree(tgt_path)
                else:
                    tgt_path.unlink()
                logger.debug(f"删除已存在的目标: {tgt_path}")
            else:
                logger.error(f"目标已存在: {tgt_path}")
                return False
        
        try:
            os.symlink(src_path, tgt_path)
            logger.info(f"创建链接: {tgt_path} -> {src_path}")
            return True
        except Exception as e:
            logger.error(f"创建链接失败: {e}")
            return False
    
    @staticmethod
    def batch_create(src: str | None = None, tgt: str | None = None) -> int:
        """批量创建符号链接
        :params:
            :src: 源目录路径
            :tgt: 目标目录路径
        :return: 成功创建的链接数量
        """
        src = src or "/data/.home"
        tgt = tgt or str(Path.home())
        logger.debug(f"{src=}, {tgt=}")
        
        src_path = Path(src).expanduser().resolve()
        tgt_path = Path(tgt).expanduser().resolve()
        
        if not src_path.exists() or not src_path.is_dir():
            logger.error(f"源目录不存在: {src_path}")
            return 0
        
        count = 0
        for item in src_path.iterdir():
            if item.is_dir():
                link_path = tgt_path / item.name
                if LinkManager.create(str(item), str(link_path), force=True):
                    count += 1
        
        logger.info(f"成功创建 {count} 个链接")
        return count


if __name__ == "__main__":
    # >>>>>>>>>>>>>>>>>>>>[ 使用示例 ]>>>>>>>>>>>>>>>
    LinkManager.batch_create("/data/.home", str(Path.home()))