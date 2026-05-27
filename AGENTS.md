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
- cargo build    
- cargo run    
- code review
- redev
- fix 
- update docstring
- git commit
- update readme
