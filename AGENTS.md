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

## ENV

```toml
[env]
system="manjaro"
shell_rc="$HOME/.zshrc"
cpu="intel 12400f"
gpu="amd redeon rx 6750 GRE 12GB"
proxy=["socks5h://127.0.0.1:1080", "socks5h://127.0.0.1:7890"]
```

## 开发规范

1. 编码前先思考
   不要预设。不要掩饰困惑。摆明权衡取舍。
2. 简洁至上
   用最少的代码解决问题。不做任何推测性开发。
3. 外科手术式改动
   只动必须动的地方。只清理你自己造成的混乱。
4. 目标驱动执行
   定义成功标准。循环迭代直到验证通过。

## rust代码要求

- 工业级架构设计
- rs文件DOC完整
- 单元测试完整
- debug详细
- 文件职责单一性
- 函数和文件命名可读性高

## rust 开发流程

需求分析 -> 解决方案 -> 方案部署 -> cargo check -> cargo test -> cargo run -p xxx --release -- -c /path/config.toml -> cargo fmt
