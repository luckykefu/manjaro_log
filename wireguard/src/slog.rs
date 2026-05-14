//! 日志系统
//!
//! 提供日志级别控制、彩色输出日志宏（sdebug/sinfo/swarn/serror）以及
//! 部署步骤进度函数（step/ok/info）
//!
//! ============================
//! | 函数/宏 | 说明 | 级别 |
//! |----------|------|------|
//! | set_level | 设置日志级别 | — |
//! | enabled | 检查某级别是否启用 | — |
//! | slog::log | 输出日志（文件:行 消息） | 按参数 |
//! | sdebug! | DEBUG 级别日志 | 0 |
//! | sinfo! | INFO 级别日志 | 1 |
//! | swarn! | WARN 级别日志 | 2 |
//! | serror! | ERROR 级别日志 | 3 |
//! | step | 输出 [current/total] 步骤提示 | — |
//! | ok | 输出 ✓ 成功消息 | — |
//! | info | 输出 ℹ 信息消息 | — |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 日志宏 sdebug!/sinfo!/swarn!/serror!:
//!   1. 检查 enabled(level)
//!   2. 拼装格式: {color}{LEVEL}{reset} {file}:{line} {msg}
//!   3. println! 输出
//! step/ok/info:
//!   1. 拼装格式: {color}[n/m]{reset} msg
//!   2. println! 输出
//! 返回 -> ()

use std::sync::atomic::{AtomicU8, Ordering};

pub const DEBUG: u8 = 0;
pub const INFO: u8 = 1;
pub const WARN: u8 = 2;
pub const ERROR: u8 = 3;

static LOG_LEVEL: AtomicU8 = AtomicU8::new(DEBUG);

pub fn set_level(level: u8) {
    LOG_LEVEL.store(level, Ordering::Relaxed);
}

pub fn enabled(level: u8) -> bool {
    level >= LOG_LEVEL.load(Ordering::Relaxed)
}

fn level_str(level: u8) -> &'static str {
    match level {
        0 => "DEBUG",
        1 => "INFO",
        2 => "WARN",
        3 => "ERROR",
        _ => "UNKN",
    }
}

fn color(level: u8) -> &'static str {
    match level {
        0 => "\x1b[0;36m",
        1 => "\x1b[0;32m",
        2 => "\x1b[0;33m",
        3 => "\x1b[0;31m",
        _ => "\x1b[0m",
    }
}

pub fn log(level: u8, file: &str, line: u32, msg: &str) {
    let short = file.rsplit('/').next().unwrap_or(file);
    let c = color(level);
    let r = "\x1b[0m";
    println!("{c}{}{} {}:{} {}", level_str(level), r, short, line, msg);
}

pub fn step(current: u8, total: u8, msg: &str) {
    println!("\x1b[0;36m[{current}/{total}]\x1b[0m {msg}");
}

pub fn ok(msg: &str) {
    println!("\x1b[0;32m✓\x1b[0m {msg}");
}

pub fn info(msg: &str) {
    println!("\x1b[0;34mℹ\x1b[0m {msg}");
}

#[macro_export]
macro_rules! sdebug {
    ($($arg:tt)*) => {
        if $crate::slog::enabled($crate::slog::DEBUG) {
            $crate::slog::log($crate::slog::DEBUG, file!(), line!(), &format!($($arg)*));
        }
    };
}

#[macro_export]
macro_rules! sinfo {
    ($($arg:tt)*) => {
        if $crate::slog::enabled($crate::slog::INFO) {
            $crate::slog::log($crate::slog::INFO, file!(), line!(), &format!($($arg)*));
        }
    };
}

#[macro_export]
macro_rules! swarn {
    ($($arg:tt)*) => {
        if $crate::slog::enabled($crate::slog::WARN) {
            $crate::slog::log($crate::slog::WARN, file!(), line!(), &format!($($arg)*));
        }
    };
}

#[macro_export]
macro_rules! serror {
    ($($arg:tt)*) => {
        if $crate::slog::enabled($crate::slog::ERROR) {
            $crate::slog::log($crate::slog::ERROR, file!(), line!(), &format!($($arg)*));
        }
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_level_default_debug() {
        assert_eq!(LOG_LEVEL.load(Ordering::Relaxed), DEBUG);
    }

    #[test]
    fn test_set_level() {
        set_level(WARN);
        assert!(!enabled(DEBUG));
        assert!(!enabled(INFO));
        assert!(enabled(WARN));
        assert!(enabled(ERROR));
        set_level(DEBUG);
        assert!(enabled(DEBUG));
    }

    #[test]
    fn test_level_str() {
        assert_eq!(level_str(0), "DEBUG");
        assert_eq!(level_str(1), "INFO");
        assert_eq!(level_str(2), "WARN");
        assert_eq!(level_str(3), "ERROR");
        assert_eq!(level_str(99), "UNKN");
    }

    #[test]
    fn test_color_returns_str() {
        let c = color(0);
        assert!(c.starts_with("\x1b["));
        assert!(c.ends_with("m"));
    }

    #[test]
    fn test_enabled_threshold() {
        set_level(INFO);
        assert!(!enabled(DEBUG));
        assert!(enabled(INFO));
        assert!(enabled(WARN));
        assert!(enabled(ERROR));
        set_level(DEBUG);
    }

    #[test]
    fn test_step_does_not_panic() {
        step(1, 10, "test step");
    }

    #[test]
    fn test_ok_does_not_panic() {
        ok("test ok");
    }

    #[test]
    fn test_info_does_not_panic() {
        info("test info");
    }
}
