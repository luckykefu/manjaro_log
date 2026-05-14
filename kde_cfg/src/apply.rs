//! 应用 KDE 全局主题和光标
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | cfg  | &KdeConfig | KDE 配置(主题名称,光标名称) |
//! | 返回 |      | Result<()> | 应用结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 QT_QPA_PLATFORM=offscreen plasma-apply-lookandfeel
//!   应用全局主题(含颜色/布局/窗口装饰)
//! 2 QT_QPA_PLATFORM=offscreen plasma-apply-cursortheme
//!   设置鼠标光标
//! 返回 ->

use crate::config::KdeConfig;
use crate::exec;
use crate::{sdebug, sinfo};
use anyhow::Result;

const OFFSCREEN: &str =
    "QT_QPA_PLATFORM=offscreen DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";

/// 应用全局主题 + 光标
pub fn apply_theme(cfg: &KdeConfig) -> Result<()> {
    sdebug!("apply_theme start");

    apply_lookandfeel(cfg)?;
    apply_cursor(cfg)?;

    sinfo!("theme applied");
    Ok(())
}

/// 应用 KDE 全局主题(颜色/布局/窗口装饰)
fn apply_lookandfeel(cfg: &KdeConfig) -> Result<()> {
    sdebug!("应用全局主题: {}", cfg.lookandfeel_theme);
    let cmd = format!(
        "{} plasma-apply-lookandfeel -a {}",
        OFFSCREEN, cfg.lookandfeel_theme
    );
    exec::bash_exec(&cmd)?;
    sinfo!("全局主题已应用: {}", cfg.lookandfeel_theme);
    Ok(())
}

/// 设置鼠标光标
fn apply_cursor(cfg: &KdeConfig) -> Result<()> {
    sdebug!("设置光标主题: {}", cfg.cursor_theme);
    let cmd = format!(
        "{} plasma-apply-cursortheme '{}'",
        OFFSCREEN, cfg.cursor_theme
    );
    exec::bash_exec(&cmd)?;
    sinfo!("光标主题已设置: {}", cfg.cursor_theme);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_apply_no_panic() {
        let cfg = KdeConfig::default();
        let _ = apply_theme(&cfg);
    }
}
