# Agent Rules

在本次对话中必须记住以下Rules

## CHAT

使用 chinese 对话

对话格式如下:
需求分析: ...
解决方案: 1. 2. 3.
- 经过用户确定在执行方案
- 运行rm 命令之前必须询问用户

---

## Local ENV

```yaml
system: manjaro
shell rc: $HOME/.zshrc
rust-build: cargo build --release
cpu: intel 12400f
gpu: amd redeon rx 6750 GRE 12GB
```

---

## Shell 编码规范

- 执行pacman 使用 `--needed --noconfirm`
- `[[]]`替代 `[]`

---

# Rust 编码规范

- rs文件格式:
  - docstring完整,必须有单元测试,涵盖边界和真实测试案例
  - 函数注释清晰简洁
  - 文件职责单一
  - 文件命名必须直观展示其功能,如 convert (NO!),csv2parquet(YES!!!)
  - 命名格式统一为rust标准命名规范
- 工业级项目架构设计
- 入口:main.rs
- runner:lib.rs 在这里处理
- 每次修改文件之后的动作:
  - cargo fmt
  - cargo test
  - cargo clippy
  - cargo build --release
  - 这些动作都只针对正在开发的包
- 改动之前必须询问我你理解的意思是否准确

---

# README.md 文件格式

```markdown
## file://src/log.rs
explain
```
# log.md 
| 入参 | 参数 | 类型 | 说明 |
| ---- | ---- | ---- | ---- |
|      | ...  |      |      |
| 返回 |     |     |      |

> 详细处理逻辑ascii图示:

1 做了什么 -> 函数:
2 做了什么 ->
... ->
返回 ->
```
