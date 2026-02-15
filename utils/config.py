#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ 配置管理模块 ]>>>>>>>>>>>>>>>
"""

import logging
from functools import reduce
from pathlib import Path
from typing import Any, TypeVar
import yaml
from rich.console import Console
from rich.logging import RichHandler

T = TypeVar('T')


class Config:
    """配置管理类（单例）"""
    
    _instance: 'Config | None' = None
    
    def __new__(cls, config_path: Path | str | None = None) -> 'Config':
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self, config_path: Path | str | None = None) -> None:
        if self._initialized:
            return
        
        self._path = Path(config_path) if config_path else Path(__file__).parent.parent / "config" / "config.yaml"
        self._data: dict[str, Any] = self._load_config()
        self._initialized = True
    
    def _load_config(self) -> dict[str, Any]:
        """加载配置文件"""
        try:
            return yaml.safe_load(self._path.read_text(encoding="utf-8")) or {}
        except (FileNotFoundError, yaml.YAMLError, OSError) as e:
            Console().print(f"[yellow]配置加载失败: {e}[/yellow]")
            return {}
    
    def get(self, key: str, default: T = None) -> Any | T:
        """获取配置值（支持点号分隔）"""
        try:
            return reduce(lambda d, k: d[k], key.split("."), self._data)
        except (KeyError, TypeError):
            return default


def _setup_logger(cfg: Config) -> logging.Logger:
    """配置日志记录器"""
    logging.basicConfig(
        level=getattr(logging, cfg.get("logger.level", "DEBUG").upper(), logging.DEBUG),
        format="%(message)s",
        handlers=[RichHandler(console=Console(), rich_tracebacks=True)],
        force=True
    )
    return logging.getLogger(cfg.get("logger.name", "app"))


# >>>>>>>>>>>>>>>>>>>>[ 全局实例 ]>>>>>>>>>>>>>>>
config = Config()
logger = _setup_logger(config)


if __name__ == "__main__":
    # >>>>>>>>>>>>>>>>>>>>[ 使用示例 ]>>>>>>>>>>>>>>>
    from rich import print_json
    
    print_json(data=config._data)
    logger.debug("调试信息")
    logger.info("普通信息")
    logger.warning("警告信息")
    logger.error("错误信息")
