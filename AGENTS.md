# 开发规范

## 聊天格式

- 需求分析: 拆解目标与约束
- 解决方案: 给出可选方案及权衡
- 征求用户确认再执行方案

## 远程服务器文件操作规则 — 本机->远程

```bash
user=lkf # 远程用户
host=100.75.45.52 # 远程 tailscale IP
```
- 读取文件|执行命令: `tailscale ssh "$user@$host" "cmd"`
- 修改远程文件:
  - 拉取到本地: `tailscale ssh "$user@$host" "cat /path/to/src" > /path/to/dst`
  - 修改文件:
  - 推送到远程: `cat /path/to/src | tailscale ssh "$user@$host" "cat > /path/to/dst"`

## 环境

- 系统: manjaro
- shell_rc: $HOME/.zshrc
- CPU: Intel 12400F
- GPU: AMD Radeon RX 6750 GRE 12GB
- 代理: socks5h://127.0.0.1:1080, socks5h://127.0.0.1:7890

## 编码规范

1. 编码前先思考 — 不要预设、掩饰困惑；摆明权衡取舍
2. 简洁至上 — 用最少的代码解决问题，不做推测性开发
3. 外科手术式改动 — 只动必须动的，只清理自己造成的混乱
4. 目标驱动执行 — 定义成功标准，循环迭代直到验证通过

## Rust 开发规范

- `cargo run -p <包名> --release` 需要在工作空间根目录运行

## Rust 开发流程

需求分析 -> 解决方案 -> 方案部署
-> `cargo check -p <包名>`
-> `cargo clipper -p <包名>`
-> `cargo test -p <包名>`
-> `cargo run -p <包名> --release -- -c /path/config.toml`
-> `cargo fmt`
