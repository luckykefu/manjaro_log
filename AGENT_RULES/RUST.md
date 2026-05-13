# Rust 编码规范
## 文件规范
- docstring完整
- 单元测试完整
- 函数步骤注释完整
- 文件职责单一
- 函数职责单一
- 文件|函数命名必须直观展示其功能,如 convert->csv2parquet

## 架构规范
- 工业级项目架构设计
- main.rs:入口
- lib.rs:逻辑处理
- 其余文件分类存放
- 每次修改文件之后的动作:
  - cargo fmt
  - cargo test
  - cargo build 
  - 这些动作都只针对正在开发的工作空间

## 文件范例
```rust
//! DOC
//!
use ...
fn fn() ->  {
    //! 1.
    //! 2.
    let result =  
    println!("{}", result);
    result
}

#[test]
fn test_fn() {
    
}
```
