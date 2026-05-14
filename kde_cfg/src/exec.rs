//! Shell 命令执行工具函数
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | cmd_str | &str | bash 命令内容 |
//! |      | envs | &[(&str, &str)] | 环境变量列表 |
//! | 返回 | | Result<()> | 执行结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 执行bash命令 -> bash_exec:
//!   构建 Command 执行 bash -c
//!   检查退出状态码
//!   记录stdout日志
//! 2 带环境变量执行 -> run_with_env:
//!   设置额外环境变量后执行
//! 返回 ->

use anyhow::{Context, Result};
use std::process::Command;

use crate::{sdebug, serror};

/// 执行 bash 命令,返回 Result
pub fn bash_exec(cmd_str: &str) -> Result<()> {
    sdebug!("执行命令: {}", cmd_str);
    let output = Command::new("bash")
        .arg("-c")
        .arg(cmd_str)
        .output()
        .with_context(|| format!("执行命令失败: {}", cmd_str))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        serror!("命令退出码非零: {}\nstderr: {}", output.status, stderr);
        anyhow::bail!("命令 `{}` 失败,退出码: {}", cmd_str, output.status);
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    if !stdout.is_empty() {
        sdebug!("stdout: {}", stdout.trim_end());
    }
    Ok(())
}

/// 带环境变量执行 bash 命令
pub fn run_with_env(cmd_str: &str, envs: &[(&str, &str)]) -> Result<()> {
    sdebug!("执行命令(env): {}", cmd_str);
    let mut cmd = Command::new("bash");
    cmd.arg("-c").arg(cmd_str);
    for (k, v) in envs {
        cmd.env(k, v);
    }
    let output = cmd
        .output()
        .with_context(|| format!("执行命令失败(env): {}", cmd_str))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        serror!("命令退出码非零: {}\nstderr: {}", output.status, stderr);
        anyhow::bail!("命令 `{}` 失败,退出码: {}", cmd_str, output.status);
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    if !stdout.is_empty() {
        sdebug!("stdout: {}", stdout.trim_end());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bash_exec_echo() {
        assert!(bash_exec("echo hello").is_ok());
    }

    #[test]
    fn test_bash_exec_false_fails() {
        let r = bash_exec("false");
        assert!(r.is_err());
    }

    #[test]
    fn test_run_with_env() {
        let r = run_with_env("echo $TEST_VAR", &[("TEST_VAR", "hello")]);
        assert!(r.is_ok());
    }

    #[test]
    fn test_run_with_env_false_fails() {
        let r = run_with_env("false", &[("A", "1")]);
        assert!(r.is_err());
    }
}
