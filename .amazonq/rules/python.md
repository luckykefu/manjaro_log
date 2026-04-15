---
name: python-skill
description: Python 编码规范与技巧
---

# Python Skill

### 函数都要有简单的逻辑描述

### 使用高级表达式

### 函数参数用 `*args / **kwargs`

```python
def fn(*args, **kwargs) -> None:
    print(args)   # tuple
    print(kwargs) # dict
    return None

fn(1, 2, a=3)  # args=(1,2)  kwargs={"a":3}

### 参数解包
args = [1, 2]
kwargs = {"c": 3}
fn(*args, **kwargs)
```

### 运行时类型检查

```python
from typing import get_args
def fn(x: str | list):
    assert isinstance(x, get_args(str | list)), f"期望 str|list，得到 {type(x)}"
```

### 生成器惰性计算

### 计算相关的fn使用缓存

```python
from functools import lru_cache
@lru_cache(maxsize=128)
def fib(n): return fib(n-1)+fib(n-2) if n>1 else n
```
