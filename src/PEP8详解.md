# PEP 8 Python 代码风格指南详解

## 一、命名规范

### 1. 变量和函数 - snake_case
```python
# ✅ 正确
user_name = "Alice"
total_count = 100
def calculate_sum(a, b):
    return a + b

# ❌ 错误
userName = "Alice"  # camelCase
TotalCount = 100    # PascalCase
```

### 2. 类名 - PascalCase
```python
# ✅ 正确
class UserAccount:
    pass

class DataProcessor:
    pass

# ❌ 错误
class user_account:  # snake_case
    pass
```

### 3. 常量 - UPPER_CASE
```python
# ✅ 正确
MAX_RETRIES = 3
API_KEY = "xxx"
DEFAULT_TIMEOUT = 30

# ❌ 错误
max_retries = 3  # 小写
MaxRetries = 3   # PascalCase
```

### 4. 私有变量 - _leading_underscore
```python
class MyClass:
    def __init__(self):
        self._private_var = 1      # 单下划线：内部使用
        self.__very_private = 2    # 双下划线：名称改写
        self.public_var = 3        # 无下划线：公开

# ✅ 正确
_internal_function()  # 模块内部函数

# ❌ 错误
__magic__ = 1  # 双下划线仅用于特殊方法
```

### 5. 特殊方法 - __dunder__
```python
# ✅ 正确（Python 内置）
def __init__(self):
    pass

def __str__(self):
    pass

# ❌ 错误（自定义不要用双下划线）
def __my_method__(self):  # 不要自创 dunder
    pass
```

---

## 二、代码布局

### 1. 缩进 - 4个空格
```python
# ✅ 正确
def function():
    if condition:
        do_something()
        do_another()

# ❌ 错误
def function():
  if condition:  # 2个空格
    do_something()
```

### 2. 行长度 - 最多79字符
```python
# ✅ 正确
result = some_function(
    arg1, arg2, arg3,
    arg4, arg5
)

# ❌ 错误
result = some_function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)  # 超过79字符
```

### 3. 空行
```python
# ✅ 正确
import os
import sys  # 标准库

import numpy  # 第三方库

from mymodule import myfunction  # 本地模块


class MyClass:  # 类前2个空行
    pass


def my_function():  # 顶层函数前2个空行
    pass


class AnotherClass:
    def method1(self):  # 方法间1个空行
        pass
    
    def method2(self):
        pass

# ❌ 错误
import os
import sys
import numpy  # 没有分组
from mymodule import myfunction
class MyClass:  # 没有空行
    pass
def my_function():  # 没有空行
    pass
```

### 4. 导入顺序
```python
# ✅ 正确
# 1. 标准库
import os
import sys
from pathlib import Path

# 2. 第三方库
import numpy as np
import pandas as pd

# 3. 本地模块
from myapp.utils import helper
from myapp.config import settings

# ❌ 错误
import numpy  # 混乱的顺序
import os
from myapp.utils import helper
import sys
```

---

## 三、空格使用

### 1. 运算符周围
```python
# ✅ 正确
x = 1
y = 2
z = x + y
result = (x + y) * (x - y)

# ❌ 错误
x=1  # 缺少空格
y = 2
z=x+y  # 缺少空格
result = ( x+y )*( x-y )  # 括号内多余空格
```

### 2. 逗号后面
```python
# ✅ 正确
my_list = [1, 2, 3, 4]
my_dict = {"a": 1, "b": 2}
function(arg1, arg2, arg3)

# ❌ 错误
my_list = [1,2,3,4]  # 逗号后缺少空格
function(arg1,arg2,arg3)
```

### 3. 函数调用
```python
# ✅ 正确
function(arg1, arg2)
my_list[0]
my_dict["key"]

# ❌ 错误
function (arg1, arg2)  # 函数名后多余空格
my_list [0]  # 括号前多余空格
my_dict ["key"]
```

### 4. 关键字参数
```python
# ✅ 正确
def function(arg1, arg2=None):
    pass

function(arg1=1, arg2=2)

# ❌ 错误
def function(arg1, arg2 = None):  # = 周围多余空格
    pass

function(arg1 = 1, arg2 = 2)
```

---

## 四、注释

### 1. 行内注释
```python
# ✅ 正确
x = x + 1  # 增加计数器

# ❌ 错误
x = x + 1 #增加计数器  # 缺少空格
x = x + 1  #增加计数器  # 缺少空格
```

### 2. 块注释
```python
# ✅ 正确
# 这是一个块注释
# 用于解释下面的代码块
# 每行都以 # 开头
def function():
    pass

# ❌ 错误
#这是一个块注释  # 缺少空格
#用于解释下面的代码块
```

### 3. 文档字符串
```python
# ✅ 正确
def function(arg1, arg2):
    """
    函数简短描述
    
    详细描述...
    
    :param arg1: 参数1说明
    :param arg2: 参数2说明
    :return: 返回值说明
    """
    pass

# ❌ 错误
def function(arg1, arg2):
    # 这不是文档字符串
    pass
```

---

## 五、表达式和语句

### 1. 比较
```python
# ✅ 正确
if x is None:
    pass

if x is not None:
    pass

if x in my_list:
    pass

# ❌ 错误
if x == None:  # 应该用 is
    pass

if not x is None:  # 应该用 is not
    pass
```

### 2. 布尔值
```python
# ✅ 正确
if my_list:  # 检查非空
    pass

if not my_list:  # 检查空
    pass

# ❌ 错误
if len(my_list) > 0:  # 冗余
    pass

if my_list == []:  # 冗余
    pass
```

### 3. 返回语句
```python
# ✅ 正确
def function():
    if condition:
        return True
    return False

# ❌ 错误
def function():
    if condition:
        return True
    else:  # 不需要 else
        return False
```

---

## 六、类型注解

### 1. 变量注解
```python
# ✅ 正确
name: str = "Alice"
age: int = 30
prices: list[float] = [1.0, 2.0]
data: dict[str, int] = {"a": 1}

# ❌ 错误
name:str = "Alice"  # 缺少空格
age : int = 30  # 多余空格
```

### 2. 函数注解
```python
# ✅ 正确
def function(arg1: str, arg2: int = 0) -> bool:
    return True

# ❌ 错误
def function(arg1:str, arg2:int=0)->bool:  # 缺少空格
    return True
```

---

## 七、实战示例

### 当前 config.py 的 PEP 8 分析

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""配置管理模块"""  # ✅ 文档字符串

from pathlib import Path  # ✅ 导入顺序正确
from typing import Any
import yaml
import logging
from rich.console import Console
from rich.logging import RichHandler

console = Console()  # ✅ 小写变量


class Config:  # ✅ PascalCase 类名
    """配置管理类"""  # ✅ 文档字符串
    
    def __init__(self) -> None:  # ✅ 类型注解
        self._data: dict[str, Any] = self._load_config()  # ✅ 私有变量
    
    def _load_config(self) -> dict[str, Any]:  # ✅ 私有方法
        """加载配置文件"""
        config_path = Path(__file__).parent.parent / "config" / "config.yaml"
        
        try:
            with open(config_path, encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        except Exception as e:
            console.print(f"[yellow]配置加载失败: {e}[/yellow]")
            return {}
    
    def get(self, key: str, default: Any = None) -> Any:  # ✅ 类型注解
        """获取配置值（支持点号分隔）"""
        value = self._data
        
        for k in key.split("."):
            if not isinstance(value, dict):
                return default
            value = value.get(k)
            if value is None:
                return default
        
        return value


config = Config()  # ✅ 小写实例

logging.basicConfig(  # ✅ 正确格式
    level=getattr(logging, config.get("logger.level", "DEBUG").upper()),
    format="%(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)]
)

logger = logging.getLogger(config.get("logger.name", "app"))  # ✅ 小写实例
```

### PEP 8 评分: 10/10 ✅

---

## 八、快速检查清单

```
✅ 命名规范
  - 变量/函数: snake_case
  - 类名: PascalCase
  - 常量: UPPER_CASE
  - 私有: _leading_underscore

✅ 代码布局
  - 缩进: 4个空格
  - 行长: 最多79字符
  - 空行: 类前2行，函数前2行，方法间1行
  - 导入: 标准库 → 第三方 → 本地

✅ 空格使用
  - 运算符周围有空格
  - 逗号后有空格
  - 函数调用无空格
  - 关键字参数 = 无空格

✅ 注释
  - 行内注释: # 空格
  - 文档字符串: """..."""

✅ 表达式
  - None 用 is/is not
  - 布尔值直接判断
  - 避免冗余 else
```

---

## 九、工具推荐

### 1. 检查工具
```bash
# flake8 - PEP 8 检查
pip install flake8
flake8 config.py

# pylint - 更严格检查
pip install pylint
pylint config.py

# black - 自动格式化
pip install black
black config.py
```

### 2. IDE 集成
```
VSCode: Python 扩展自动检查
PyCharm: 内置 PEP 8 检查
```

---

## 十、总结

PEP 8 核心原则：
1. **一致性** - 代码风格统一
2. **可读性** - 代码易于理解
3. **简洁性** - 避免冗余

**记住**: 代码是写给人看的，机器只是顺便执行！
