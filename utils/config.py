#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# >>>>>>>>>>>>>>>配置管理模块>>>>>>>>>>>>>>>>

from pathlib import Path
from typing import Any
import yaml
import logging
from rich.console import Console
from rich.logging import RichHandler

# >>>>>>>>>>>>>>>全局 console>>>>>>>>>>>>>>>>
console = Console()

class Config:
    """配置管理类"""
    
    def __init__(self) -> None:
        """初始化配置"""
        self._data: dict[str, Any] = self._load_config()
    
    def _load_config(self) -> dict[str, Any]:
        """加载配置文件"""
        config_path = Path(__file__).parent.parent / "config" / "config.yaml"
        
        try:
            with open(config_path, encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        except FileNotFoundError:
            logger.error(f"配置文件不存在: {config_path}")
            return {}
        except yaml.YAMLError as e:
            logger.error(f"YAML 解析错误: {e}")
            return {}
        except Exception as e:
            logger.error(f"配置加载失败: {e}")
            return {}
    
    def get(self, key: str, default: Any = None) -> Any:
        """获取配置值
        :params:
            :key: 配置键，支持点号分隔（如 'database.path'）
            :default: 默认值
        :return: 配置值或默认值
        """
        value = self._data
        
        for k in key.split("."):
            if not isinstance(value, dict):
                return default
            value = value.get(k)
            if value is None:
                return default
        
        return value


# 全局配置实例
config = Config()

class Logger:
    """日志配置类
    :params:
        :name: logger 名称
        :level: 日志级别
    :return: Logger 实例
    """
    
    def __init__(self, name: str = "app", level: str = config.get("logger.level", "DEBUG").upper()):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        
        # >>>>>>>>>>>>>>>只在没有 handlers 时添加>>>>>>>>>>>>>>>>
        if not self.logger.handlers:
            handler = RichHandler(console=console, markup=True)
            self.logger.addHandler(handler)
            init_mst = f"[bold green]Logger Initialized:[/bold green] [yellow]{name}[/yellow] at level [cyan]{level}[/cyan]"
            self.logger.info(init_mst)
    
    def __getattr__(self, name: str):
        """代理 logger 的所有方法"""
        return getattr(self.logger, name)

# >>>>>>>>>>>>>>>全局 logger>>>>>>>>>>>>>>>>
logger = Logger()


if __name__ == "__main__":
    # >>>>>>>>>>>>>>>>>>>>使用示例>>>>>>>>>>>>>>>>
    from rich import print_json
    
    logger.debug("调试信息")
    logger.info("普通信息")
    logger.warning("警告信息")
    logger.error("错误信息")
    
    print_json(data=config._data)