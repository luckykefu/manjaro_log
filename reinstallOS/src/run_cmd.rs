//! 系统命令执行工具
//!
//! 提供统一的命令执行接口，支持 dry-run 模式。
//! 所有执行均记录详细 debug 日志（命令、参数、退出码）。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | RunConfig.cmd | | String | 可执行命令名或路径 |
//! | RunConfig.args | | Vec<String> | 命令参数列表 |
//! | 返回 | | Result<()> | 命令执行成功 |
//! | | | Result<String> | 命令 stdout 输出 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 execute_and_wait(config) ->
//!    |- sdebug 记录 cmd + args
//!    +- Command::new(config.cmd).args(config.args).status()
//!    +- 非零退出码 -> anyhow::bail
//!    +- Ok(())
//!
//! 2 capture_output(config) ->
//!    |- sdebug 记录 cmd + args
//!    +- Command::new(config.cmd).args(config.args).output()
//!    +- 非零退出码 -> anyhow::bail(stderr)
//!    +- Ok(stdout.trim())
//! 返回 -> Ok(()) / Ok(String)

use crate::sdebug;
use std::process::Command;

/// 命令执行配置
pub struct RunConfig {
    /// 可执行命令（如 "pacman", "lookandfeeltool"）
    pub cmd: String,
    /// 命令参数列表
    pub args: Vec<String>,
}

impl RunConfig {
    pub fn new(cmd: &str, args: &[&str]) -> Self {
        Self {
            cmd: cmd.to_string(),
            args: args.iter().map(|s| s.to_string()).collect(),
        }
    }
}

/// 执行命令并等待完成
pub fn execute_and_wait(config: &RunConfig) -> anyhow::Result<()> {
    sdebug!("{} {}", config.cmd, config.args.join(" "));
    let status = Command::new(&config.cmd).args(&config.args).status()?;
    if !status.success() {
        anyhow::bail!("{} failed with exit code {:?}", config.cmd, status.code());
    }
    Ok(())
}

/// 执行命令并捕获 stdout
pub fn capture_output(config: &RunConfig) -> anyhow::Result<String> {
    sdebug!("{} {}", config.cmd, config.args.join(" "));
    let out = Command::new(&config.cmd).args(&config.args).output()?;
    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr);
        anyhow::bail!("{} failed: {stderr}", config.cmd);
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_execute_and_wait_echo() {
        let cfg = RunConfig::new("echo", &["hello"]);
        assert!(execute_and_wait(&cfg).is_ok());
    }

    #[test]
    fn test_execute_and_wait_false() {
        let cfg = RunConfig::new("false", &[]);
        assert!(execute_and_wait(&cfg).is_err());
    }

    #[test]
    fn test_capture_output_echo() {
        let cfg = RunConfig::new("echo", &["hello"]);
        let out = capture_output(&cfg).unwrap();
        assert_eq!(out, "hello");
    }

    #[test]
    fn test_capture_output_false() {
        let cfg = RunConfig::new("false", &[]);
        assert!(capture_output(&cfg).is_err());
    }

    #[test]
    fn test_run_config_new() {
        let cfg = RunConfig::new("ls", &["-la", "/tmp"]);
        assert_eq!(cfg.cmd, "ls");
        assert_eq!(cfg.args, vec!["-la", "/tmp"]);
    }
}
