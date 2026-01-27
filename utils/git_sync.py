#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ Git 同步工具 ]>>>>>>>>>>>>>>>
"""

import subprocess
from pathlib import Path
from typing import Any

try:
    from config import logger
except ImportError:
    from .config import logger


def git_sync(repo_path: str | None = ".", commit_msg: str | None = "auto commit") -> Any:
    """Git 同步工具：add、commit、push
    :params:
        :repo_path: 仓库路径，默认当前目录
        :commit_msg: 提交信息，默认 "auto commit"
    :return: 执行结果
    """
    logger.debug(f"{repo_path=}, {commit_msg=}")
    
    repo = Path(repo_path).resolve()
    
    try:
        subprocess.run(["git", "add", "."], cwd=repo, check=True)
        subprocess.run(["git", "commit", "-m", commit_msg], cwd=repo, check=True)
        subprocess.run(["git", "push"], cwd=repo, check=True)
        logger.info("Git sync completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Git sync failed: {e}")
        return False


if __name__ == "__main__":
    git_sync(".", "Update notebook")
