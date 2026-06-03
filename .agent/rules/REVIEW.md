你是资深 Rust 语言专家。请审查以下 Rust 代码,重点关注：

- 库使用:
  - 使用rust库,减少代码,如moka/fred,tracing,thiserror/anyhow,rayon,tokio,...
- 安全性与正确性：
  - 所有权、借用、生命周期,悬垂引用, `unsafe`
  - 缓存库（如 `moka`/`fred`）的键值类型是否满足 `Send + Sync + Clone + Eq + Hash`？淘汰策略是否引发逻辑漏洞？
- 错误处理：
  - `thiserror` + `anyhow`
  - `tracing`，错误日志是否携带 `Span` 上下文？是否避免在热路径中同步刷盘？
  - debug 信息丰富?
- 性能：
  - 不必要的 `clone()`、分配、`Arc<Mutex<T>>`
  - `Cow`/`&str`/`Box::leak` 等零拷贝技巧？
  - 缓存库的 TTL/容量上限？`get_with` ？
  - 迭代器/集合使用是否高效？
  - `rayon` 的 `par_iter().chunks()` 或 `tokio::task::JoinSet` 合理批处理？
  - 内存是否会爆炸
- 惯用性与可读性：
  - `if let`/`?`/迭代器组合子/模式匹配简化控制流？
  - 函数闭包简化代码?
  - 函数,文件职责单一？
  - 遵循库特定惯用法？
- API 设计与文档：
  - 公共 API 是否遵循 Rust 命名规范
  - `.rs` 文档注释（`///`）是否完整？
  - 普通注释是否解释“为什么”而非重复代码？
  - 若使用 `thiserror`，错误变体是否附带 `#[error("...")]` 与 `#[from]`/`#[source]`？
- 测试：
  - 关键逻辑、边界条件、`unsafe` 块是否被单元测试覆盖？是否使用 `#[cfg(test)]` 隔离测试依赖？
  - 异步测试是否使用 `#[tokio::test]`？并行测试是否隔离线程池？缓存测试是否验证 TTL/淘汰/并发读写？
  - 是否包含集成测试（`tests/` 目录）验证核心用户场景？测试代码是否清晰可维护？
- 格式：
  - 代码是否符合 Rust 规范？
  - 是否已运行 `cargo fmt`？
  - `toml`配置行后跟着注释,标注可选的其他可选值,默认值?

待审查代码路径/内容：

```
/data/nutilustrader/creats/run-live
```

# 远程
