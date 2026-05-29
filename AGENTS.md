# AGENT RULES

## 本次对话应始终记住以下规则

## CHAT FORMAT

- LANG: CHINESE
- REPLY FMT:
  - 需求分析: ...
  - 解决方案:
    - 1.
    - 2.
    - 3.
    - 4. 用户补充
  - 征求用户确认再执行方案

## LOCAL ENV

```toml
[env]
system="manjaro"
shell_rc="$HOME/.zshrc"
cpu="intel 12400f"
gpu="amd redeon rx 6750 GRE 12GB"
proxy=["socks5://127.0.0.1:1080", "socks5://127.0.0.1:7890"]
```

## Shell RULES

### dev

```bash
#! /usr/bin/bash
# sudo pacman -S --needed --noconfirm <pkgs>
# yay -S --needed --noconfirm <pkgs>
# jq for json
# yq for yaml
# shellcheck
# more debug
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# replace [ ] with [[ ]]
# replace if then fi with [[ ]] && xxx || xxx
if [[ "$BASH_SOURCE" != "$0" ]]; then
    main "$@"
fi
```


## RUST RULES

### 开发规范

- 代码简洁高级优雅
- 工业级架构设计
- 优先考虑并发,异步,高性能,
- 完整性:
  - docstring
  - 注释
  - 单元测试
  - 详细debug
  - 错误处理 thiserror
- 职责单一性:
  - 文件
  - 函数
- 命名直观: 如 convert->csv2parquet

```
main_workspace/
    src/
        main.rs # 入口,负责lib.rs 中的runner的调用,方便移植
        lib.rs # runner,具体逻辑的实现,
        ...
    Cargo.toml # edition = "2024"
```

### 工作流

- 按照用户要求和开发规范编写代码
- cargo check    
- fix 
- cargo fmt    
- cargo test    
- cargo clippy    
- cargo build    # 编译时针对性编译,防止项目太大耗时太长
- cargo run    
- code review
- redev
- fix 
- update docstring
- git commit
- update readme

旨在减少常见 LLM 编程错误的行为准则。请根据需要与特定项目的指令合并。

权衡：这些准则倾向于“谨慎”而非“速度”。对于琐碎的任务，请自行判断。
1. 编码前先思考

不要预设。不要掩饰困惑。摆明权衡取舍。

在实现之前：

    明确陈述你的假设。如果不确定，请询问。
    如果存在多种解读方式，请全部呈现——不要默默选择其一。
    如果存在更简单的方法，请说明。在有理有据时提出异议。
    如果不清楚，请停止。指出令人困惑的地方。提问。

2. 简洁至上

用最少的代码解决问题。不做任何推测性开发。

    不提供超出要求的特性。
    不对仅使用一次的代码进行抽象。
    不提供未要求的“灵活性”或“可配置性”。
    不对不可能发生的场景编写错误处理。
    如果你写了 200 行代码，但本可以用 50 行实现，请重写。
    问问自己：“资深工程师会觉得这太复杂了吗？”如果是，请简化。

3. 外科手术式改动

只动必须动的地方。只清理你自己造成的混乱。

当编辑现有代码时：

    不要“改进”相邻的代码、注释或格式。
    不要重构没有损坏的部分。
    匹配既有风格，即使你有不同的写法。
    如果你注意到了不相关的死代码，请提及——不要直接删除。

当你的改动产生冗余（孤儿代码）时：

    移除由你的改动导致的不再使用的导入、变量或函数。
    不要移除原本就存在的死代码，除非被要求。
    测试准则：每一行改动都应该能直接追溯到用户的需求。

4. 目标驱动执行

定义成功标准。循环迭代直到验证通过。

将任务转化为可验证的目标：

    “添加验证” → “为无效输入编写测试，然后使其通过”。
    “修复 Bug” → “编写一个能复现该 Bug 的测试，然后使其通过”。
    “重构 X” → “确保重构前后的测试均通过”。

对于多步骤任务，陈述简要计划：

    [步骤] → 验证：[检查项]
    [步骤] → 验证：[检查项]
    [步骤] → 验证：[检查项]

# README.md 格式
要求简洁
```markdown
# 介绍
# 配置
```toml

```
# 执行流程

```
# 文件处理逻辑需在行后注释清楚
proj/
  Cargo.toml
  src/
    main.rs # 入口
    lib.rs # 公开接口
    config.rs # 配置结构体,默认值,配置加载函数
    ...
    
```
# 用法
```bash
cargo run -p proj
```
```
