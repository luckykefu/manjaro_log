//! 命令执行工具
//!
//! 封装本地命令执行、sudo、SCP 文件传输、SSH 远程执行等操作
//!
//! ============================
//! | 函数 | 说明 | 返回 |
//! |------|------|------|
//! | run | 运行本地命令，捕获 stdout | Result<String> |
//! | sudo | sudo 执行，捕获 stdout | Result<String> |
//! | bash_exec | bash -c 执行，捕获 stdout | Result<String> |
//! | sudo_bash_exec | sudo bash -c 执行，捕获 stdout | Result<String> |
//! | sudo_ignore_output | sudo 执行，丢弃 stdout | Result<String> |
//! | scp | 通过 SCP 推送文件到远程 | Result<String> |
//! | ssh | SSH 远程执行命令 | Result<String> |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 所有函数:
//!   1. 构造 Command
//!   2. .output() 同步执行
//!   3. 检查 status.success()
//!   4. 成功 -> Ok(stdout.trim())
//!   5. 失败 -> bail(stderr)
//! 返回 -> Result<String>

use anyhow::{Context, Result, bail};
use std::process::Command;

pub fn run(program: &str, args: &[&str]) -> Result<String> {
    let output = Command::new(program)
        .args(args)
        .output()
        .with_context(|| format!("failed to execute {program}"))?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("{program} failed: {stderr}")
    }
}

pub fn sudo(args: &[&str]) -> Result<String> {
    let output = Command::new("sudo")
        .args(args)
        .output()
        .context("sudo failed")?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("sudo failed: {stderr}")
    }
}

pub fn bash_exec(script: &str) -> Result<String> {
    let output = Command::new("bash")
        .args(["-c", script])
        .output()
        .context("bash execution failed")?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("bash exec failed: {stderr}")
    }
}

pub fn sudo_bash_exec(script: &str) -> Result<String> {
    let output = Command::new("sudo")
        .args(["bash", "-c", script])
        .output()
        .context("sudo bash execution failed")?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("sudo bash exec failed: {stderr}")
    }
}

pub fn sudo_ignore_output(args: &[&str]) -> Result<String> {
    let output = Command::new("sudo")
        .args(args)
        .output()
        .context("sudo failed")?;
    if output.status.success() {
        Ok(String::new())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("sudo failed: {stderr}")
    }
}

pub fn scp(source: &str, dest: &str) -> Result<String> {
    let output = Command::new("scp")
        .args([
            "-o",
            "StrictHostKeyChecking=accept-new",
            "-o",
            "ConnectTimeout=5",
            source,
            dest,
        ])
        .output()
        .context("scp failed")?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("scp failed: {stderr}")
    }
}

pub fn ssh(host: &str, command: &str) -> Result<String> {
    let output = Command::new("ssh")
        .args(["-o", "ConnectTimeout=5", host, command])
        .output()
        .with_context(|| format!("ssh to {host} failed"))?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("ssh {host} failed: {stderr}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_echo() {
        let out = run("echo", &["hello"]).unwrap();
        assert_eq!(out, "hello");
    }

    #[test]
    fn test_run_false() {
        assert!(run("false", &[]).is_err());
    }

    #[test]
    fn test_run_not_found() {
        assert!(run("nonexistent_cmd_xyz", &[]).is_err());
    }

    #[test]
    fn test_bash_exec() {
        let out = bash_exec("echo hello from bash").unwrap();
        assert_eq!(out, "hello from bash");
    }

    #[test]
    fn test_bash_exec_fail() {
        assert!(bash_exec("exit 1").is_err());
    }

    #[test]
    fn test_ssh_no_conn() {
        assert!(ssh("192.0.2.1", "whoami").is_err());
    }
}
