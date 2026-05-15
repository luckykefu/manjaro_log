//! mihomo 配置生成器 CLI
//!
//! 从订阅链接自动下载、解析代理节点，生成 mihomo (Clash Meta) 配置文件。
//!
//! ============================
//! 入参说明
//! | 参数 | 类型 | 说明 |
//! |------|------|------|
//! | --subscribe-link | String | 订阅链接 URL |
//! | --output-dir | PathBuf | 输出目录 (默认: ~/.config/mihomo) |
//! | --nameserver | Option<String> | DNS 服务器 IP (默认: 192.168.1.1) |
//! | --proxy | Option<String> | HTTP 代理地址 (订阅链接被墙时使用) |
//! | --skip-start | bool | 跳过启动提示 |
//! =============================
//! ASCII 图示处理逻辑:
//!
//! 1. 解析 CLI 参数 -> clap::Parser
//! 2. 构造 RunConfig -> lib::RunConfig
//! 3. 调用 lib::run(config) -> 下载/解析/生成
//! 4. 打印结果 -> 退出

use clap::Parser;

/// 命令行参数结构
#[derive(Parser)]
#[command(
    name = "mihomo",
    about = "Generate mihomo config from subscription link"
)]
struct CliArgs {
    /// 订阅链接 URL
    #[arg(long)]
    subscribe_link: String,

    /// 输出目录 (存放 config.yaml 和 providers/)
    #[arg(long, default_value = "/home/lkf/.config/mihomo")]
    output_dir: std::path::PathBuf,

    /// DNS 服务器 IP (必须为当前网络可达的 IP)
    #[arg(long)]
    nameserver: Option<String>,

    /// HTTP 代理地址，如 http://127.0.0.1:7897
    #[arg(long)]
    proxy: Option<String>,

    /// 跳过启动提示
    #[arg(long)]
    skip_start: bool,
}

fn main() -> anyhow::Result<()> {
    let args = CliArgs::parse();

    let config = mihomo::RunConfig {
        subscribe_link: args.subscribe_link,
        output_dir: args.output_dir,
        nameserver: args.nameserver.unwrap_or_else(|| "192.168.1.1".into()),
        proxy: args.proxy,
        skip_start: args.skip_start,
    };

    mihomo::run(config)
}
