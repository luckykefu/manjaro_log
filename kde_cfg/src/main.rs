//! kde_cfg CLI 入口
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | args | Vec<String> | 命令行参数 |
//! | 返回 |      | Result<()> | 执行结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 加载环境变量配置 -> KdeConfig::from_env
//! 2 解析 CLI 参数 -> 选择运行模块
//! 3 执行模块 -> run_module
//! 返回 ->

use anyhow::Result;
use kde_cfg::config::KdeConfig;
use kde_cfg::slog;
use kde_cfg::{sdebug, sinfo};
use std::env;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    let module = args.get(1).map(|s| s.as_str()).unwrap_or("all");

    // 设置日志级别
    if env::var("KDE_CFG_DEBUG").is_ok() {
        slog::set_level(slog::DEBUG);
    } else {
        slog::set_level(slog::INFO);
    }

    sdebug!("kde_cfg starting, module: {}", module);
    let cfg = KdeConfig::from_env();
    sinfo!("kde_cfg: 开始配置模块 [{}]", module);

    kde_cfg::run_module(&cfg, module)?;

    sinfo!("kde_cfg: 完成");
    Ok(())
}
