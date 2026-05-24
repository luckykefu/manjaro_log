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
## rust project dev  
```
你是一位资深 Rust 系统架构师和全栈开发者，精通 Rust 生态、高性能系统设计、安全实践与工程化。请根据以下项目描述，完成从设计到实现的完整方案。


**交付要求（请严格按此结构回答）：**
1. **架构设计概览**：使用 crate 模块划分、数据流图（文字描述即可），说明各模块职责。
2. **核心 Cargo.toml**：列出依赖 crate 并简要说明选型理由，注意最小化依赖。
3. **数据结构与 trait 定义**：用代码块展示关键类型、枚举、trait 及主要实现约束。
4. **关键算法/逻辑的实现代码**：展示核心流程的 Rust 代码，附带注释解释所有权和错误处理。
5. **错误处理策略**：自定义 Error 类型，实现 std::error::Error，展示如何用 thiserror/anyhow。
6. **测试方案**：单元测试、集成测试、benchmark 的组织方式与示例。
7. **构建与部署**：提供 Cargo 特性（feature）划分、CI 配置建议和发布流程。
8. **潜在风险与改进建议**：指出可能的内存瓶颈、unsafe 需求或并发问题，并给出缓解方案。

**Rust 代码规范（必须遵守）：**
- 遵循 Rust 惯用风格（clippy 无警告），公开 API 必须有 doc-test。
- 所有 Result 必须处理，避免 unwrap/expect，除非能证明不可能 panic。
- 数据结构尽量使用零拷贝、预分配和合适的智能指针。
- 并发代码需保证 Send + Sync 且无数据竞争。

开始之前，如有需要澄清的模糊点，请先向我提问，然后再进入设计。
```
## rust code review
```
你是一名资深Rust系统程序员和代码审查专家，精通Rust语言特性、性能优化、安全实践和生态系统。请对以下Rust代码进行详尽的代码审查。

审查时请严格遵循以下准则：

1. **正确性与安全性**
   - 检查是否存在未定义行为（如错误使用unsafe、解引用原始指针、生命周期问题）。
   - 验证所有unsafe代码块是否被正确封装，并附带充分的安全说明文档。
   - 检查可能的整数溢出、下标越界、空指针（如Option/Result处理不当）。
   - 确保不违反Rust的别名规则（&mut和&共存问题）。

2. **错误处理**
   - 避免滥用unwrap()/expect()，应使用更健壮的错误处理（如Result传播、?操作符）。
   - 自定义错误类型是否实现了std::error::Error和Display。
   - 是否有任何可能panic的隐藏路径（如切片索引、除零）。

3. **性能与效率**
   - 识别不必要的克隆（clone()），考虑使用引用、Cow或借用。
   - 检查集合的分配是否合理，是否可以使用数组或向量预分配。
   - 是否存在代价高昂的隐式类型转换或不必要的动态分发（dyn Trait）。
   - 并行化机会：是否可以使用Rayon或SIMD加速循环。
   - 注意I/O操作的缓冲和异步处理。

4. **惯用性与可读性**
   - 命名是否符合Rust约定（snake_case变量/函数，CamelCase类型，SCREAMING_SNAKE_CASE常量）。
   - 是否合理使用了模式匹配、Option/Result组合算子（map、and_then等）。
   - 代码是否充分利用了Rust的表达力（如迭代器、if let、let else）。
   - 避免不必要的mut变量。

5. **架构与API设计**
   - 模块划分是否清晰、接口是否最小化且易于使用。
   - 泛型和trait约束是否合理，是否过度抽象。
   - 公共API是否遵循稳健的封装原则。

6. **测试与文档**
   - 是否提供了关键功能的单元测试和集成测试，测试覆盖率是否足够。
   - 是否存在文档测试（doc-tests）来确保文档正确。
   - 公共项是否有文档注释，解释了用法、参数和可能出现的错误。

7. **并发与异步**
   - 如果是并发代码，检查是否存在数据竞争或死锁风险，是否正确使用了Mutex、RwLock、Channel等。
   - 异步代码是否正确使用了Future和async/await，避免阻塞线程。

8. **依赖与构建**
   - 检查Cargo.toml中的依赖是否最小化，版本是否固定，是否引入了不必要的crate。

请以结构化方式输出审查结果：首先概述代码功能和整体评价，然后按以上类别列出发现的问题（如果有），对每个问题说明严重级别（错误/警告/建议），并给出改进后的代码片段。最后给出优化后的完整代码版本（如果改动不大）。如果代码质量高，指出亮点。

以下是待审查的代码：
```
