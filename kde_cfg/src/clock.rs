//! 配置 KDE 时钟显示秒数
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | 返回 |      | Result<()> | 配置结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 解析 plasma-org.kde.plasma.desktop-appletsrc
//!   逐行扫描匹配 [Containments][N][Applets][M]
//!   读取 plugin 值,定位 digitalclock 实例
//! 2 对每个 digitalclock 写入:
//!   Configuration/Appearance/showSeconds=Always
//!   Configuration/Appearance/use24hFormat=2
//! 3 重启 plasmashell
//! 返回 ->

use anyhow::{Context, Result};
use std::env;
use std::fs;
use std::path::PathBuf;

use crate::exec;
use crate::{sdebug, sinfo};

const BUS: &str = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";

fn appletsrc_path() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| "/tmp".into());
    PathBuf::from(home).join(".config/plasma-org.kde.plasma.desktop-appletsrc")
}

/// 配置所有数字时钟显示秒数
pub fn config_kde_clock() -> Result<()> {
    sdebug!("config_kde_clock start");

    exec::bash_exec("kwriteconfig6 --file kded5rc --group Module-clock --key autoload true")?;

    let path = appletsrc_path();
    let content =
        fs::read_to_string(&path).with_context(|| format!("读取 {} 失败", path.display()))?;

    let clocks = find_digital_clocks(&content);
    if clocks.is_empty() {
        anyhow::bail!("未找到 digitalclock applet");
    }

    for (containment, applet) in &clocks {
        configure_clock(containment, applet)?;
    }

    sinfo!("kde clock configured ({} clocks)", clocks.len());
    Ok(())
}

/// 解析 appletsrc,返回所有 digitalclock 的 (containment_id, applet_id)
fn find_digital_clocks(content: &str) -> Vec<(String, String)> {
    let mut clocks = Vec::new();
    let mut current_containment: Option<String> = None;
    let mut current_applet: Option<String> = None;

    for line in content.lines() {
        let trimmed = line.trim();

        if let Some(caps) = parse_section(trimmed, "Containments", "Applets") {
            current_containment = Some(caps.0);
            current_applet = Some(caps.1);
        } else if let Some(plugin) = trimmed.strip_prefix("plugin=") {
            if plugin.trim() == "org.kde.plasma.digitalclock" {
                if let (Some(c), Some(a)) = (&current_containment, &current_applet) {
                    clocks.push((c.clone(), a.clone()));
                }
            }
        }
    }

    clocks
}

/// 从 `[Containments][N][Applets][M]` 提取 N 和 M
fn parse_section(line: &str, outer: &str, inner: &str) -> Option<(String, String)> {
    let pattern = format!("[{}]", outer);
    if !line.starts_with(&pattern) {
        return None;
    }
    let rest = line.strip_prefix(&pattern)?;
    let rest = rest.strip_prefix('[')?;
    let outer_id = rest.split(']').next()?.to_string();

    let pattern2 = format!("[{}]", inner);
    let rest2 = rest.split(']').skip(1).collect::<Vec<_>>().join("]");
    let rest2 = rest2.strip_prefix(&pattern2)?;
    let rest2 = rest2.strip_prefix('[')?;
    let inner_id = rest2.split(']').next()?.to_string();

    Some((outer_id, inner_id))
}

/// 用 kwriteconfig6 配置单个时钟 applet
fn configure_clock(containment: &str, applet: &str) -> Result<()> {
    let cfg = format!(
        "{} kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
         --group Containments --group {} --group Applets --group {} \
         --group Configuration --group Appearance",
        BUS, containment, applet
    );

    exec::bash_exec(&format!("{} --key showSeconds Always", cfg))?;
    exec::bash_exec(&format!("{} --key use24hFormat --type int 2", cfg))?;
    sdebug!("clock [{}][{}] configured", containment, applet);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_find_digital_clocks_empty() {
        assert!(find_digital_clocks("").is_empty());
    }

    #[test]
    fn test_find_digital_clocks_found() {
        let content = "\
[Containments][1][Applets][2]
plugin=org.kde.plasma.digitalclock
";
        let clocks = find_digital_clocks(content);
        assert_eq!(clocks.len(), 1);
        assert_eq!(clocks[0], ("1".to_string(), "2".to_string()));
    }

    #[test]
    fn test_find_digital_clocks_skips_other() {
        let content = "\
[Containments][1][Applets][2]
plugin=org.kde.plasma.other
";
        assert!(find_digital_clocks(content).is_empty());
    }

    #[test]
    fn test_parse_section_valid() {
        let r = parse_section("[Containments][5][Applets][10]", "Containments", "Applets");
        assert_eq!(r, Some(("5".to_string(), "10".to_string())));
    }

    #[test]
    fn test_parse_section_invalid() {
        assert!(parse_section("not a section", "Containments", "Applets").is_none());
    }
}
