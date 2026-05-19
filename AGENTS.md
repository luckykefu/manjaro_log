# AGENT RULES

---

## 本次对话应始终记住以下规则

---

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

---

## LOCAL ENV

```toml
[local.env]
system="manjaro"
shell_rc="$HOME/.zshrc"
cpu="intel 12400f"
gpu="amd redeon rx 6750 GRE 12GB"
proxy=["socks5://127.0.0.1:1080", "socks5://127.0.0.1:7890"]
```

---

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

### review

- debug是否覆盖
- 代码是否简洁优雅

## RUST RULES

### 开发规范

- 代码简洁高级优雅
- 高可读性,高可维护性,高可测试性
- 优先考虑并发,异步,高性能,
- 完整性:
  - docstring
  - 单元测试
  - 详细debug
  - 错误处理 thiserror
- 职责单一性:
  - 文件
  - 函数
  - 如果一个文件之有一个函数,那么文件名和函数名保持一致
- 命名直观: 如 convert->csv2parquet

```
main_workspace/
    bin/
    config/ # 配置文件
        config.toml # 实际运行的配置
        config.example.toml # 包含所有配置,且每行配置后面跟着注释,
    data/ # 数据文件
    reports/ # 报告文件
    src/
        main.rs # 入口,负责lib.rs 中的runner的调用,方便移植
        lib.rs # runner,具体逻辑的实现,
        log.rs # 统一日志处理
        error.rs # 错误处理
        model_1.rs # 模块1 代码少则放到一个文件里
        model_2/ # 模块2 代码多则放到一个目录下
            mod.rs
    Cargo.toml # edition = "2024"
```

### 工作流

- 按照用户要求和开发规范编写代码
- cargo check -p xxx
- fix 
- cargo fmt -p xxx
- cargo test -p xxx
- cargo clippy -p xxx
- cargo build -p xxx
- cargo run -p xxx
- code review
- re dev
- fix 
- update docstring
- git commit
- update readme
