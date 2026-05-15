//! mihomo 配置生成器 - 从订阅链接生成 mihomo (Clash Meta) 配置文件
//!
//! 工作流程:
//! ```text
//! 订阅链接
//!   │
//!   ▼
//! subscribe::download()  ─── 下载 base64 编码的订阅内容
//!   │
//!   ▼
//! parser::parse()  ─── 解析 vless/anytls/tuic/hysteria2/vmess 节点
//!   │
//!   ▼
//! config::generate()  ─── 生成 config.yaml + providers/my_sub.yaml
//!   │
//!   ▼
//! 启动 mihomo: mihomo -d <output_dir>
//! ```

pub mod check;
pub mod config;
pub mod parser;
pub mod slog;
pub mod subscribe;

use anyhow::Result;
use std::path::PathBuf;

/// mihomo 配置生成器的输入参数
#[derive(Debug, Clone)]
pub struct RunConfig {
    /// 订阅链接 URL
    pub subscribe_link: String,

    /// 输出目录 (存放 config.yaml 和 providers/)
    pub output_dir: PathBuf,

    /// DNS 服务器 IP (必须为当前网络可达的 IP)
    pub nameserver: String,

    /// HTTP 代理地址 (用于订阅链接被墙时)
    pub proxy: Option<String>,

    /// 是否跳过启动提示
    pub skip_start: bool,
}

/// 运行完整的配置生成流程
///
/// ## 入参
/// | 参数 | 类型 | 说明 |
/// |------|------|------|
/// | config | RunConfig | 订阅链接、输出目录、DNS 等配置 |
/// | 返回 | Result<()> | 成功或错误 |
///
/// ## ASCII 处理逻辑
/// ```text
/// 1. 下载订阅 -> subscribe::download(link, proxy)
/// 2. 解码 base64 -> parser::decode(raw)
/// 3. 解析节点 -> parser::parse_proxies(text)
/// 4. 生成配置 -> config::generate(proxies, output_dir, nameserver)
/// 5. 打印启动命令
/// 6. 连通性测试 -> check::check_connectivity()
/// ```
pub fn run(config: RunConfig) -> Result<()> {
    let raw = subscribe::download(&config.subscribe_link, config.proxy.as_deref())?;
    let text = parser::decode(&raw)?;
    let proxies = parser::parse_proxies(&text)?;

    if proxies.is_empty() {
        anyhow::bail!("no proxies found in subscription");
    }

    config::generate(&proxies, &config.output_dir, &config.nameserver)?;

    let output_str = config.output_dir.display().to_string();
    sinfo!(
        "\n🚀 Start mihomo:\n   nohup mihomo -d {} > /tmp/mihomo.log 2>&1 & disown",
        output_str
    );

    if !config.skip_start {
        check::check_connectivity(9097, 7897, &output_str);
    }

    Ok(())
}
