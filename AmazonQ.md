# AmazonQ Agent Rules

## CHAT

使用 chinese 对话

对话格式如下:
需求分析: ...
解决方案: 1. 2. 3.

经过用户确定在执行方案
是否保存文件,保存到哪里必须经过同意!!!

---

## ENV

```yaml
system: manjaro
shell rc: $HOME/.zshrc
python-env: uv run
cpu: intel 12400f
gpu: amd redeon rx 6750 GRE 12GB
```

---

## 行为规范

- 没让改的地方绝对不改
- 和py库有关的问题,必须查询源码库再回答
- 操作notebook时,json.load
- test 文件统一放在 test 文件夹下
- ide 里运行shell需要加上代理

```bash
export https_proxy=socks5h://127.0.0.1:1080 http_proxy=socks5h://127.0.0.1:1080

```

---

## Python 编码规范

> 可读性

- 函数有简单 docstring, 包含逻辑和参数
- 步骤有注释
- 命名自解释，无魔法数字，用常量替代
- 函数单一职责，一个函数只负责处理一个事务.

> 可维护性

- DRY：重复逻辑抽函数
- 使用高级表达式（推导式/三元/解包）
- 参数用 `*args / **kwargs`

> 可靠性

- 类型注解全覆盖
- 运行时用 `assert isinstance(x, get_args(T))` 检查
- 明确错误信息，不静默失败（禁用裸 `except: return None`）

> 性能

- 重复计算用 `@lru_cache`
- 联网加重试机制
- 大数据用生成器替代列表推导
- 循环外提前计算不变量

> 可测试性

- 依赖注入替代全局状态，方便 mock

---

## Shell 编码规范

- 运行python脚本使用 `uv run` 命令前缀
- 执行pacman 使用 `--needed --noconfirm`
