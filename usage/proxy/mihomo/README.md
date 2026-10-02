# mihomo 代理启动手册

## 1. 项目概览

### 1.1 架构

本机 (Manjaro) 运行 **mihomo**, 提供统一 **mixed 端口** (http + socks5 合一) 本地代理; 可选 **TUN 模式** 实现全局透明代理 + fake-ip 路由。

```
本机 (Manjaro)
┌─────────────────────────────────┐
│             mihomo               │
│  mixed-port  7890 (http+socks5)  │
│  TUN (可选)   fake-ip 198.18.0.1/16 │
└─────────────────────────────────┘
```

### 1.2 技术参数

| 参数 | 值 |
| --- | --- |
| mixed-port | `7890` (http + socks5 合一) |
| TUN 模式 | 需显式开启 (由 start.sh 注入) |
| fake-ip 范围 | `198.18.0.1/16` (默认) |
| TUN 排除接口 | `tailscale0` |
| fake-ip 路由 | `ip rule ... lookup 2022 pref 8999` |
| 健康检查 | `curl mixed-port generate_204` 等 204 |
| 日志 | `mihomo.log` (运行时生成) |
| systemd | 无 (由 start.sh 管理) |

## 2. 文件清单 (相对路径)

与本文档**同目录**, 相对路径引用, 完整实现在仓库内同名文件:

| 文件 | 端 | 作用 |
| --- | --- | --- |
| `start.sh` | 本机 | 启动器: 生成运行配置 + 启动 + 等端口 + (TUN)修路由 + 健康检查 |
| `config copy.yaml` | 本机 | 配置模板 (维护基准) |
| `config.yaml` | 本机 | 运行配置 (由模板复制 / 由 SS 生成) |
| `cache.db` | 本机 | 运行缓存 (自动生成) |
| `开发文档.md` | 本机 | 开发细节, 与本文档并存 |

## 3. 根据配置启动服务

按**启动所需步骤**编排 (完整实现见 `start.sh`):

### 开启TUN

- 传入 `--tun` 才启用 `tun.enable=true`; 并排除 `tailscale0` (**fake-ip 198.18.0.1/16**, 避免与 Tailscale 冲突)。
- 缺省 (无 `--tun`): `tun.enable=false`, 仅提供本地 mixed-port 代理。

### 生成运行配置

- 基于 `config copy.yaml` 模板 → 生成 `config.yaml` 作为运行配置。
- 节点由 `../shadowsocks-rust/ss_to_mihomo.sh` 生成 (详见 ss_to_mihomo.sh)。

### 启动 mihomo

- `start.sh` 以 `nohup sudo mihomo -d <同目录> > mihomo.log 2>&1 &` 后台启动。

### 等待端口

- 轮询 (最多 8 次 × 2s) 等待 mixed-port (7890) 端口监听。

### 修复路由 (TUN 时)

- 为 fake-ip 范围 (默认 `198.18.0.1/16`) 添加 `ip rule ... lookup 2022 pref 8999`; 幂等 (先删后加)。
- 修复 tailscale 路由: 排除 `tailscale0` (避免吞掉 Tailscale 内置路由)。

### 健康检查

- 轮询 (最长 120s) `curl -x http://127.0.0.1:7890 https://www.google.com/generate_204`。
- 拿到 `204` 即输出 `✓ 代理正常`。

## 4. 停止与验证

### 停止

- 停止: `pkill -x mihomo`, 等待后超时 `-9` 强杀。

### 验证

- 健康检查: `curl -x http://127.0.0.1:7890 https://www.google.com/generate_204` → 期望 204。
- 出口: `curl -x socks5h://127.0.0.1:7890 https://ipinfo.io`。

## 5. 故障排查

| 症状 | 排查 |
| --- | --- |
| 7890 未监听 | 查看 `mihomo.log`; 检查 `config.yaml` 语法 |
| TUN 不通 | 确认 `--tun` 已传; 检查 fake-ip 路由 (lookup 2022 pref 8999); tailscale0 排除 |
| 健康检查超时 | 检查出口连通性; mixed-port 是否被占用 |

## 6. 注意事项

- `config copy.yaml` 为手动编辑基准; 运行配置为 `config.yaml`。
- TUN 需 root (由 start.sh sudo 处理); 修改 fake-ip 路由时排除 `tailscale0`。
- 与 `../shadowsocks-rust/ss_to_mihomo.sh` 联动, 由 SS 配置生成 mihomo `config.yaml`。
