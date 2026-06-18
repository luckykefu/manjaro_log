## 常用库替代本地代码

异步:tokio
并行:rayon
错误:thiserror/anyhow
缓存:mock/fred
日志:tracing
反序列:serde

## rust代码要求

- 工业级架构设计
- rs文件DOC完整
- 单元测试完整
- debug详细
- 文件职责单一性
- 函数和文件命名可读性高

## rust 开发流程

需求分析 -> 解决方案 -> 方案部署 -> cargo check -> cargo test -> cargo run -p xxx --release -- -c /path/config.toml -> cargo fmt
