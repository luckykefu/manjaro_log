#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ Yay 配置管理工具 ]>>>>>>>>>>>>>>>
"""

import json
from pathlib import Path
try:
    from config import logger
except ImportError:
    from .config import logger


class YayManager:
    """Yay 配置管理器"""
    
    @staticmethod
    def configure(config_dir: str | None = None):
        """配置 yay
        :params:
            :config_dir: 配置目录路径
        :return: 是否成功
        """
        logger.debug(f"{config_dir=}")
        
        config_dir = Path(config_dir or Path.home() / ".config" / "yay")
        config_dir.mkdir(parents=True, exist_ok=True)
        
        config_file = config_dir / "config.json"
        
        config_data = {
            "editor": "nano",
            "pacmanbin": "pacman",
            "pacmanconf": "/etc/pacman.conf",
            "answerclean": "All",
            "removemake": "ask",
            "maxconcurrentdownloads": 5,
            "cleanAfter": False,
            "batchinstall": True,
            "DevelCheckUpdate": False
        }
        
        try:
            with open(config_file, 'w') as f:
                json.dump(config_data, f, indent=4)
            
            logger.info(f"✓ yay config created: {config_file}")
            return True
            
        except Exception as e:
            logger.error(f"创建 yay 配置失败: {e}")
            return False


if __name__ == "__main__":
    # >>>>>>>>>>>>>>>>>>>>[ 使用示例 ]>>>>>>>>>>>>>>>
    YayManager.configure()
