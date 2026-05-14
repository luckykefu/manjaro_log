//! kde_cfg 运行器
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | cfg  | &KdeConfig | KDE 配置 |
//! |      | module | &str | 模块名 |
//! | 返回 |      | Result<()> | 运行结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 模块分发、执行、统一重启 plasmashell:
//! theme    -> theme::install_mac_themes
//! apply    -> apply::apply_theme
//! clock    -> clock::config_kde_clock
//! wallpaper -> wallpaper::config_kde_wallpaper
//! general  -> general::config_kde_general
//! all      -> 依次执行以上所有
//! 最后     -> systemctl restart plasma-plasmashell
//! 返回 ->

pub mod apply;
pub mod clock;
pub mod config;
pub mod exec;
pub mod general;
pub mod slog;
pub mod theme;
pub mod wallpaper;

use anyhow::Result;
pub use config::KdeConfig;

const BUS: &str = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";

fn restart_plasma() {
    exec::bash_exec(&format!(
        "{} systemctl --user restart plasma-plasmashell.service 2>/dev/null || true",
        BUS
    ))
    .ok();
}

/// 运行所有 KDE 配置步骤后重启 plasma
pub fn run(cfg: &KdeConfig) -> Result<()> {
    theme::install_mac_themes(cfg)?;
    apply::apply_theme(cfg)?;
    clock::config_kde_clock()?;
    wallpaper::config_kde_wallpaper()?;
    general::config_kde_general()?;
    restart_plasma();
    Ok(())
}

/// 运行指定模块后重启 plasma
pub fn run_module(cfg: &KdeConfig, module: &str) -> Result<()> {
    let result = match module {
        "theme" => theme::install_mac_themes(cfg),
        "apply" => apply::apply_theme(cfg),
        "clock" => clock::config_kde_clock(),
        "wallpaper" => wallpaper::config_kde_wallpaper(),
        "general" => general::config_kde_general(),
        "all" => run(cfg),
        _ => anyhow::bail!(
            "未知模块: {}. 可选: all, theme, apply, clock, wallpaper, general",
            module
        ),
    };
    if module != "all" {
        restart_plasma();
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_module_unknown() {
        let cfg = KdeConfig::default();
        assert!(run_module(&cfg, "unknown").is_err());
    }
}
