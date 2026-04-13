# 使用中文进行对话

## 编程环境

- CPU: Intel 12400F
- GPU: AMD 6750 GRE 12G
- 系统: Linux Arch Manjaro
- 终端: zsh

## 代理配置

- Python: `socks5h://192.168.0.103:7897`

## Python 规则

- pylance 标准编程
- **类型提示**：必须使用 Python 的 Type Hints (typing 模块)
- **错误处理**：需要包含完整的 try-except 块，妥善处理 [特定的错误，如网络超时、文件不存在]
- **代码风格**：遵循 PEP 8，变量命名清晰。重试机制,缓存机制,

## Shell 命令

```bash
# 安装包
sudo pacman -S --needed --noconfirm pkg

```

## 日志规范

- 参数验证使用 `logger.debug(f"{msg=}")`
- 返回结果使用 `logger.info(f"{msg=}")`
- 异常错误使用 `logger.error(f"{msg=}")`

## 代码结构

- 使用注释分隔符标记代码块：`# [ 标题 ]`
- 标准代码块顺序：参数验证 → 业务逻辑 → 返回结果

## Python 文件模板

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# [ 模块功能介绍 ]

"""

from config import config,logger


def example_function(param1: str, param2: int) -> None:
    """
    示例函数
    :params:
        :param1: 参数1说明
        :param2: 参数2说明
    :return: 返回值说明
    """
    # [ 参数验证 ]
    logger.debug(f"{param1=}, {param2=}")

    # [ 业务逻辑 ]
    result = None

    # [ 返回结果 ]
    logger.info(f"{result=}")
    return result


if __name__ == "__main__":
    # [ 使用示例 ]
    example_function(param1="test", param2=123)
```
