# mihomo

从订阅链接自动下载、解析代理节点，生成 [mihomo](https://github.com/MetaCubeX/mihomo) (Clash Meta) 配置文件。

## 使用

```bash
cargo run -p mihomo -- \
  --subscribe-link "https://your-subscription-link" \
  --output-dir ~/.config/mihomo \
  --nameserver 192.168.1.1

# 订阅被墙时通过已有代理下载
cargo run -p mihomo -- \
  --subscribe-link "https://your-subscription-link" \
  --output-dir ~/.config/mihomo \
  --nameserver 192.168.1.1 \
  --proxy http://127.0.0.1:7897
```

## 选项

| 参数 | 说明 |
|------|------|
| `--subscribe-link` | 订阅链接 URL |
| `--output-dir` | 输出目录（默认: `~/.config/mihomo`） |
| `--nameserver` | DNS 服务器 IP（默认: `192.168.1.1`） |
| `--proxy` | HTTP 代理地址（可选，订阅被墙时使用） |
| `--skip-start` | 跳过启动提示 |

## 生成的文件

```
<output-dir>/
├── config.yaml           # mihomo 主配置
└── providers/
    └── my_sub.yaml       # 代理节点列表
```

## 启动

```bash
nohup mihomo -d ~/.config/mihomo > /tmp/mihomo.log 2>&1 & disown
```

## 结构

```
mihomo/
├── Cargo.toml
└── src/
    ├── main.rs          # CLI 入口
    ├── lib.rs           # 编排器
    ├── slog.rs          # 日志
    ├── subscribe.rs     # 订阅下载
    ├── parser.rs        # URI 解析
    └── config.rs        # 配置生成
```

## 关联文件

- [USAGE.md](./USAGE.md) — 完整使用指南
