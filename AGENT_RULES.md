# AGENT RULES

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
- `[[ ]]` 替代 `[ ]`
- using `[[ ]] && xxx || xxx`, not `if then fi`
- `sudo pacman -S --needed --noconfirm <pkgs>`
- `yay -S --needed --noconfirm <pkgs>`
- jq操作json文件
- yq操作yaml文件
- shellcheck 检查代码
- 文件架构如下:
```
sh_workspace/
  main.sh:入口
  lib.sh:runner
  src/:按照执行流程组织文件结构,每个步骤一个文件,酌情合并代码少的步骤
    model_1.sh
    ...
```
- 开发完成后: run & fix
## 6. Rust 规范

### 文件规范
- docstring完整: 
  - 介绍
  - 入参返回说明表格
  - ASCII图示处理逻辑
- 独立配置结构体作为参数
- 单元测试完整
- 具备详细debug输出
- 文件职责单一
- 函数职责单一
- 文件|函数|参数的命名都必须直观展示其功能,如 convert->csv2parquet

### 架构规范
要求: 工业级项目架构设计
```
main_workspace/
  src/
  Cargo.toml # edition = "2024"
  sub_workspace/
    src/
      main.rs # cli配置+runner入口
      lib.rs # runner逻辑处理调用其他模块执行
      slog.rs # 日志处理
      model_1.rs # 模块1 代码少则放到一个文件里
      model_2/ # 模块2 代码多则放到一个目录下
        mod.rs # 模块导出
        model_2_1.rs # 模块2.1
    Cargo.toml # edition = "2024"
    
```
### 每次修改文件之后的动作:
- 代码审查直到通过标准
- 更新文档DOCSTRING
- cargo fmt
- cargo test
- cargo build
- cargo run
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
