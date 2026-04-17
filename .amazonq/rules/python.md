---
name: python-skill
description: Python 编码规范与技巧
---

# Python Skill

## 可读性
- 函数有简单 docstring, 包含逻辑和参数
- 命名自解释，无魔法数字，用常量替代
- 函数单一职责，< 20 行

## 可维护性
- DRY：重复逻辑抽函数
- 使用高级表达式（推导式/三元/解包）
- 参数用 `*args / **kwargs`

## 可靠性
- 类型注解全覆盖
- 运行时用 `assert isinstance(x, get_args(T))` 检查
- 明确错误信息，不静默失败（禁用裸 `except: return None`）

## 性能
- 重复计算用 `@lru_cache`
- 联网加重试机制
- 大数据用生成器替代列表推导
- 循环外提前计算不变量

## 可测试性
- 依赖注入替代全局状态，方便 mock

## 评估指标

| 维度 | 标准 | 工具 |
|------|------|------|
| 函数长度 | < 20 行 | pylint |
| 圈复杂度 | < 10 | radon |
| 重复率 | < 5% | pylint |
| 类型注解 | 全覆盖 | mypy |
| 测试覆盖 | > 80% | pytest-cov |
