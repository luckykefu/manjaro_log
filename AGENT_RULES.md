# AGENT_RULES.md

## 1. 阅读规则

阅读以下内容
记住规则
本次对话都应该始终保持规则

## 2. 对话格式 — CHAT

CHAT LANG: chinese
CHAT fmt:
- 需求分析: ...
- 解决方案:
  - 1.
  - 2.
  - 3.
  - 4. 用户补充
- 经过用户确定在执行方案

## 3. 本地环境

```yaml
system: manjaro
shell rc: $HOME/.zshrc
cpu: intel 12400f
gpu: amd redeon rx 6750 GRE 12GB
proxy: [socks5://127.0.0.1:1080, socks5://127.0.0.1:7897]
```
## 5. Shell 规范

### 语法
- `[[ ]]` 替代 `[ ]`

### 包管理
- 系统包: `sudo pacman -S --needed --noconfirm <pkgs>`
- AUR 包: `yay -S --needed --noconfirm <pkgs>`

### 文件示例
```bash
#!/bin/bash
# file.sh
# 介绍
# 入参
# ASCII图示处理逻辑

fn() {
    local func="<fn>"
    local var=${1:-}
    # 1.
    # 2.
    cat << EOF
执行函数: $func
参数: $var
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    fn "$@"
fi
```

## 6. Rust 规范

### 文件规范
- docstring完整: 介绍,入参返回说明,ASCII图示处理逻辑
- 独立配置结构体作为参数
- 单元测试完整
- 具备详细debug输出
- 文件职责单一
- 函数职责单一
- 文件|函数|参数的命名都必须直观展示其功能,如 convert->csv2parquet

### 架构规范
- 工业级项目架构设计
- main.rs:cli配置+runner入口
- lib.rs: runner逻辑处理调用其他文件夹/文件执行
- 其余文件分类存放.模块导出
- 每次修改文件之后的动作:
  - 代码审查直到通过标准
  - 更新文档DOCSTRING
  - cargo fmt
  - cargo test
  - cargo build
  - 这些动作都只针对正在开发的工作空间

### 文件范例
```rust
//! 功能解释
//! ...
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | ...  |      |      |
//! | 返回  |     |     |      |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 做了什么 -> 函数1:
//! 2 做了什么 -> 函数2:
//! ... -> ...
//! 返回 ->
//!

use ...

fn fn() ->  {
    // 步骤1...
    // 步骤2...
    let result =
    println!("{}", result);
    result
}

#[test]
fn test_fn() {

}
```

## 7. README.md 格式

### 关联文件
- file://src/log.rs

### 功能解释
...

### 入参说明
| 入参 | 参数 | 类型 | 说明 |
| ---- | ---- | ---- | ---- |
|      | ...  |      |      |
| 返回 |     |     |      |

### ASCII图示处理逻辑

```
1 做了什么 -> 函数1:
2 做了什么 -> 函数2:
... -> ...
返回 ->
```
