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
    println!("{c}{}:{}{} {} {}{}", short, line, r, level_str(level), msg, r);
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
}
