# AGENT RULES

---

## 本次对话应始终记住以下规则

---

## CHAT FORMAT

- LANG: chinese
- reply format:
  - 需求分析: ...
  - 解决方案:
    - 1.
    - 2.
    - 3.
    - 4. 用户补充
  - 征求用户确认再执行方案

---

## LOCAL ENV

- system: manjaro
- shell rc: $HOME/.zshrc
- cpu: intel 12400f
- gpu: amd redeon rx 6750 GRE 12GB
- proxy: [socks5://127.0.0.1:1080, socks5://127.0.0.1:7897]

---

## Shell RULES

- `[[ ]]` 替代 `[ ]`
- using `[[ ]] && xxx || xxx`, not `if then fi`
- `sudo pacman -S --needed --noconfirm <pkgs>`
- `yay -S --needed --noconfirm <pkgs>`
- jq for json文件
- yq for yaml文件
- shellcheck for synxc
- 文件架构如下:
```
sh_workspace/
  main.sh: # 入口
  model_1.sh: # step 1
  ...
  README.md # 项目介绍
  WorFlow.md # 项目执行流程
  Structure.md # 项目文件结构
```
- 开发完成后: run & fix

## RUST RULES

### 架构规范

要求: 工业级项目架构设计

```
main_workspace/
  src/
    main.rs
    lib.rs
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
    README.md # 项目介绍
    WorFlow.md # 项目执行流程
    Structure.md # 项目文件结构
  Cargo.toml # edition = "2024"
  config.toml # 实际运行的配置
  config.example.toml # 每行配置注释清楚
  README.md # 项目介绍
  WorFlow.md # 项目执行流程
  Structure.md # 项目文件结构
```
### 文件规范
- docstring完整:
```
//! 介绍
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
```
- 独立配置结构体作为参数
- 单元测试完整
- 具备详细debug输出
- 文件职责单一
- 函数职责单一
- 文件|函数|参数的命名都必须直观展示其功能,如 convert->csv2parquet


### 每次修改文件之后的动作:

- 代码审查直到通过标准
- 更新文件DOCSTRING
- cargo fmt
- cargo test
- cargo build
- cargo run
- 这些动作都只针对正在开发的工作空间
