//! 显示器刷新率设置
//!
//! 通过 kscreen-doctor 列出显示器模式，按分辨率降序匹配目标刷新率。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | DisplayConfig.output | | String | 显示器输出 ID（如 "1"） |
//! | DisplayConfig.rate | | String | 目标刷新率（如 "60"） |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 set_display_rate(config) ->
//! 2    |- setup_display_env -> 检测 WAYLAND_DISPLAY + DBUS
//! 3    |- kscreen-doctor -o -> 解析所有模式
//! 4    |- 筛选匹配刷新率的模式
//! 5    +- 按分辨率降序排序，选最高者
//! 6    +- kscreen-doctor output.{id}.mode.{mid}
//! 返回 -> Ok(())

use crate::{run_cmd, sdebug, sinfo};

/// 显示器配置
pub struct DisplayConfig {
    pub output: String,
    pub rate: String,
}

impl DisplayConfig {
    pub fn new(output: String, rate: String) -> Self {
        Self { output, rate }
    }
}

/// 设置指定显示器输出的刷新率
pub fn set_display_rate(config: &DisplayConfig) -> anyhow::Result<()> {
    sdebug!(
        "set_display_rate output={} rate={}",
        config.output,
        config.rate
    );
    setup_display_env()?;
    let out = run_cmd::capture_output(&run_cmd::RunConfig::new("kscreen-doctor", &["-o"]))?;
    let target: f64 = config.rate.parse().unwrap_or(0.0);
    let mut candidates: Vec<(String, u64)> = Vec::new();

    for line in out.lines() {
        if line.contains("Modes:") {
            sdebug!("raw Modes line: {line}");
            for entry in line.split_whitespace() {
                sdebug!("parsing entry: {entry}");
                if let Some((mid, mrate, w, h)) = parse_mode_entry(entry) {
                    sdebug!("parsed mode {mid} {w}x{h}@{mrate}");
                    if (mrate - target).abs() < 0.5 {
                        candidates.push((mid, w * h));
                    }
                }
            }
        }
    }

    if candidates.is_empty() {
        anyhow::bail!(
            "no {}Hz mode found for output {}",
            config.rate,
            config.output
        );
    }
    candidates.sort_by(|a, b| b.1.cmp(&a.1));
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
        "kscreen-doctor",
        &[&format!(
            "output.{}.mode.{}",
            config.output, candidates[0].0
        )],
    ))?;
    sinfo!(
        "set output {} to {}Hz (mode {})",
        config.output,
        config.rate,
        candidates[0].0
    );
    Ok(())
}

fn setup_display_env() -> anyhow::Result<()> {
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new("which", &["kscreen-doctor"])).ok();
    let uid = run_cmd::capture_output(&run_cmd::RunConfig::new("id", &["-u"]))?;
    if std::env::var("WAYLAND_DISPLAY").is_err() {
        let sock = run_cmd::capture_output(&run_cmd::RunConfig::new(
            "find",
            &[
                "/run/user",
                &uid,
                "-maxdepth",
                "1",
                "-name",
                "wayland-*",
                "-print",
                "-quit",
            ],
        ))
        .unwrap_or_default();
        if !sock.is_empty() {
            if let Some(name) = std::path::Path::new(&sock)
                .file_name()
                .and_then(|n| n.to_str())
            {
                unsafe {
                    std::env::set_var("WAYLAND_DISPLAY", name);
                }
                sdebug!("detected WAYLAND_DISPLAY={name}");
            }
        }
    }
    if std::env::var("DBUS_SESSION_BUS_ADDRESS").is_err() {
        let dbus = format!("/run/user/{uid}/bus");
        if std::path::Path::new(&dbus).exists() {
            unsafe {
                std::env::set_var("DBUS_SESSION_BUS_ADDRESS", format!("unix:path={dbus}"));
            }
            sdebug!("detected DBUS at {dbus}");
        }
    }
    Ok(())
}

fn parse_mode_entry(s: &str) -> Option<(String, f64, u64, u64)> {
    let s = s.trim();
    let colon = s.find(':')?;
    let at = s[colon..].find('@')?;
    let actual_at = colon + at;
    let mid = s[..colon].to_string();
    let res_part = &s[colon + 1..actual_at];
    let rate_str = s[actual_at + 1..].trim_end_matches(|c: char| !c.is_ascii_digit() && c != '.');
    let rate: f64 = rate_str.parse().ok()?;
    let (w, h) = parse_resolution(res_part)?;
    if mid.is_empty() {
        None
    } else {
        Some((mid, rate, w, h))
    }
}

fn parse_resolution(s: &str) -> Option<(u64, u64)> {
    let s = s.trim_end_matches('*');
    let x = s.find('x')?;
    let w: u64 = s[..x].parse().ok()?;
    let h: u64 = s[x + 1..].parse().ok()?;
    Some((w, h))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_mode_entry_standard() {
        let r = parse_mode_entry("1:2560x1440@60.00*!").unwrap();
        assert_eq!(r.0, "1");
        assert!((r.1 - 60.0).abs() < 0.01);
        assert_eq!(r.2, 2560);
        assert_eq!(r.3, 1440);
    }

    #[test]
    fn test_parse_mode_entry_no_suffix() {
        let r = parse_mode_entry("7:1920x1080@60").unwrap();
        assert_eq!(r.0, "7");
        assert!((r.1 - 60.0).abs() < 0.01);
        assert_eq!(r.2, 1920);
        assert_eq!(r.3, 1080);
    }

    #[test]
    fn test_parse_mode_entry_high_rate() {
        let r = parse_mode_entry("2:2560x1440@169.90").unwrap();
        assert!((r.1 - 169.9).abs() < 0.01);
    }

    #[test]
    fn test_parse_mode_entry_invalid() {
        assert!(parse_mode_entry("invalid").is_none());
    }

    #[test]
    fn test_display_config_new() {
        let cfg = DisplayConfig::new("1".into(), "144".into());
        assert_eq!(cfg.output, "1");
        assert_eq!(cfg.rate, "144");
    }
}
