#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ Shell RC 路径管理 ]>>>>>>>>>>>>>>>
"""

from pathlib import Path


def add_path_to_rc(path: str, rc_file: str = "~/.zshrc") -> bool:
    """添加路径到 shell rc 文件
    :params:
        :path: 要添加的路径
        :rc_file: shell rc 文件路径
    :return: 是否成功
    """
    print(f"DEBUG: {path=}, {rc_file=}")
    
    path = Path(path).expanduser().resolve()
    rc_file = Path(rc_file).expanduser()
    
    if not path.exists():
        print(f"ERROR: 路径不存在: {path}")
        return False
    
    export_line = f'export PATH="{path}:$PATH"\n'
    
    # 检查是否已存在
    if rc_file.exists():
        content = rc_file.read_text()
        if str(path) in content:
            print(f"INFO: 路径已存在于 {rc_file}")
            return True
    
    # 添加路径
    try:
        with open(rc_file, 'a') as f:
            f.write(f"\n# Added by script\n{export_line}")
        print(f"INFO: 路径已添加到 {rc_file}")
        return True
    except Exception as e:
        print(f"ERROR: 添加失败: {e}")
        return False


if __name__ == "__main__":
    add_path_to_rc("/data/.path/.ollama/bin")
