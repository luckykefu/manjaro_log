# mihomo 使用指南

> Clash Meta 内核，纯命令行代理客户端
> 安装: `sudo pacman -S archlinuxcn/mihomo`

---

## 一、从订阅连接到启动

### 方式 A：Rust 工具一行完成（推荐）

```bash
# 生成配置 + 启动
cargo run -p mihomo -- \
  --subscribe-link "https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825" \
  --output-dir ~/.config/mihomo \
  --nameserver 192.168.1.1

# 订阅被墙时，通过已有代理下载
cargo run -p mihomo -- \
  --subscribe-link "https://api3.nimenshishangdi.cc/dazhutou/eebe36f8c2eb695b9841a61eb4b03825" \
  --output-dir ~/.config/mihomo \
  --nameserver 192.168.1.1 \
  --proxy http://127.0.0.1:7897

# 启动
nohup mihomo -d ~/.config/mihomo > /tmp/mihomo.log 2>&1 & disown
```

> Rust 工具位置：`/data/.manjaro/mihomo`
> 流程: 订阅链接 → 下载 → base64解码 → 解析44节点 → 生成`config.yaml` + `providers/my_sub.yaml`

### 方式 B：直接填订阅 URL（mihomo 自动拉取）

```yaml
proxy-providers:
  my_sub:
    type: http
    url: "https://你的订阅链接"
    interval: 86400
    path: ./providers/my_sub.yaml
```

然后 `mihomo -d ~/.config/mihomo`，启动时自动下载。

### 方式 C：订阅 → 本地文件 → 启动

URL 被墙时，通过已有代理下载后再启动：

```bash
# 下载
curl -x http://127.0.0.1:7897 -sL "订阅链接" -o /tmp/sub.txt

# 转换
python3 /tmp/gen_provider.py /tmp/sub.txt ~/.config/mihomo/providers/my_sub.yaml

# 启动
nohup mihomo -d ~/.config/mihomo > /tmp/mihomo.log 2>&1 & disown
```

### 方式 D：订阅 → sing-box → 启动

```bash
sudo pacman -S archlinuxcn/sing-box
python3 /tmp/gen_singbox.py /tmp/sub.txt ~/.config/sing-box/config.json
sing-box check -c ~/.config/sing-box/config.json
sing-box run -c ~/.config/sing-box/config.json
```

---

## 二、日常管理

### 启动/停止

```bash
mihomo -d ~/.config/mihomo                    # 前台
nohup mihomo -d ~/.config/mihomo > /tmp/mihomo.log 2>&1 & disown  # 后台
sudo systemctl start mihomo                   # systemd
sudo systemctl stop mihomo
journalctl -u mihomo -f                       # 日志
```

### 切换节点

```bash
# API
curl -X PUT http://127.0.0.1:9097/proxies/proxy \
  -H "Content-Type: application/json" \
  -d '{"name":"香港节点名"}'

# TUI
sudo pacman -S archlinuxcn/clashtui
clashtui
```

### 更新订阅

```yaml
# type: http 模式下自动按 interval 更新
# 手动强制更新：
curl -X PUT http://127.0.0.1:9097/providers/proxies/my_sub
```

### 环境变量

```bash
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=socks5://127.0.0.1:7898
```

---

## 三、配置说明

### proxy-providers（订阅管理）

| 字段 | 说明 |
|------|------|
| `type: http` | 从 URL 自动拉取订阅 |
| `type: file` | 使用本地文件 |
| `url` | 订阅链接 |
| `interval` | 更新间隔（秒） |
| `path` | 本地缓存路径 |
| `health-check` | 自动测活 |

### proxy-groups（策略组）

| type | 行为 |
|------|------|
| `select` | 手动选择 |
| `url-test` | 自动选延迟最低的 |
| `fallback` | 按优先级故障切换 |

### dns（关键）

```yaml
default-nameserver:   # 必须用 IP，且当前网络可达
  - 192.168.1.1
nameserver:           # 主 DNS，解析国内域名
  - 192.168.1.1
fallback:             # 解析境外域名
  - https://doh.pub/dns-query
```

`default-nameserver` 不可达时，所有节点域名解析失败 → 全部超时。

### 路由规则执行顺序

```
从上到下依次匹配 → MATCH 兜底
DOMAIN-KEYWORD → DOMAIN-SUFFIX → IP-CIDR → GEOIP → MATCH
```

---

## 四、故障排查

```bash
# 端口是否监听
ss -tlnp | grep 7897

# 日志错误
cat /tmp/mihomo.log | grep -E "error|timeout|dns"

# 测试节点连通性
curl -s --connect-timeout 5 -x http://127.0.0.1:7897 -o /dev/null -w "%{http_code}" https://www.google.com

# 测试 DNS
getent hosts 节点域名

# 测试 default-nameserver 连通性
curl -s --connect-timeout 3 http://192.168.1.1
```

---

## 五、附录：Rust 工具结构

位置：`/data/.manjaro/mihomo/`

```
mihomo/
├── Cargo.toml
└── src/
    ├── main.rs       # CLI 参数解析 + 入口
    ├── lib.rs        # 编排器，导出模块
    ├── subscribe.rs  # 订阅下载
    ├── parser.rs     # URI 解析 (vless/anytls/tuic/hy2/vmess)
    └── config.rs     # 配置生成 (config.yaml + provider)
```

```bash
# 测试
cargo test -p mihomo

# 手动转换（不通过 CLI 时）
cargo run -p mihomo -- \
  --subscribe-link "订阅链接" \
  --output-dir ~/.config/mihomo \
  --nameserver 192.168.1.1
```

### Python 脚本（备选）

```bash
# 订阅 → Clash YAML
python3 /tmp/gen_provider.py /tmp/sub.txt ~/.config/mihomo/providers/my_sub.yaml

# 订阅 → sing-box JSON
python3 /tmp/gen_singbox.py /tmp/sub.txt ~/.config/sing-box/config.json
```

### 使用

```bash
# 从 base64 订阅 → Clash 节点文件
python3 /tmp/gen_provider.py /tmp/sub.txt ~/.config/mihomo/providers/my_sub.yaml

# 从 base64 订阅 → sing-box JSON
python3 /tmp/gen_singbox.py /tmp/sub.txt ~/.config/sing-box/config.json
```
