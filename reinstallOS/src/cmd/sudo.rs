//! 免密码 sudo 配置
//!
//! 在 /etc/sudoers.d/ 下创建用户配置，授予 NOPASSWD 权限。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | SudoConfig.user | | Option<String> | 目标用户名，None 自动检测 |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 configure_passwordless_sudo(config) ->
//! 2    |- user = config.user ?? SUDO_USER ?? USER ?? whoami
//! 3    |- id <user> 验证用户存在
//! 4    +- sudo install -m 0440 /dev/stdin /etc/sudoers.d/<user>
//! 5    +- 写入 "<user> ALL=(ALL) NOPASSWD: ALL"
//! 返回 -> Ok(())

use crate::{run_cmd, sdebug, sinfo};

/// 免密码 sudo 配置
pub struct SudoConfig {
    /// 目标用户名，None 表示自动检测
    pub user: Option<String>,
}

impl SudoConfig {
    pub fn new(user: Option<String>) -> Self {
        Self { user }
    }
}

/// 配置指定用户免密码 sudo
pub fn configure_passwordless_sudo(config: &SudoConfig) -> anyhow::Result<()> {
    sdebug!("configure_passwordless_sudo user={:?}", config.user);

    let user = resolve_user(&config.user)?;
    sdebug!("resolved user={user}");

    verify_user_exists(&user)?;

    let rule = format!("{user} ALL=(ALL) NOPASSWD: ALL\n");
    let sudoers_file = format!("/etc/sudoers.d/{user}");

    let tmp = format!("/tmp/sudoers_{user}_{}", std::process::id());
    std::fs::write(&tmp, &rule)?;
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
        "sudo",
        &["cp", &tmp, &sudoers_file],
    ))?;
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
        "sudo",
        &["chmod", "0440", &sudoers_file],
    ))?;
    std::fs::remove_file(&tmp).ok();

    sinfo!("passwordless sudo configured for {user}");
    Ok(())
}

fn resolve_user(requested: &Option<String>) -> anyhow::Result<String> {
    if let Some(u) = requested {
        if !u.is_empty() {
            return Ok(u.clone());
        }
    }
    if let Ok(u) = std::env::var("SUDO_USER") {
        if !u.is_empty() {
            return Ok(u);
        }
    }
    if let Ok(u) = std::env::var("USER") {
        if !u.is_empty() {
            return Ok(u);
        }
    }
    let out = run_cmd::capture_output(&run_cmd::RunConfig::new("whoami", &[]))?;
    if out.is_empty() {
        anyhow::bail!("cannot determine current user");
    }
    Ok(out)
}

fn verify_user_exists(user: &str) -> anyhow::Result<()> {
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new("id", &[user]))
        .map_err(|e| anyhow::anyhow!("user {user} not found: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sudo_config_new() {
        let cfg = SudoConfig::new(Some("testuser".into()));
        assert_eq!(cfg.user, Some("testuser".to_string()));
    }

    #[test]
    fn test_sudo_config_new_none() {
        let cfg = SudoConfig::new(None);
        assert_eq!(cfg.user, None);
    }

    #[test]
    fn test_resolve_user_requested() {
        let user = resolve_user(&Some("alice".into())).unwrap();
        assert_eq!(user, "alice");
    }

    #[test]
    fn test_resolve_user_empty_requested_fallsback() {
        let user = resolve_user(&Some("".into())).unwrap();
        assert!(!user.is_empty());
    }

    #[test]
    fn test_resolve_user_fallsback_to_env() {
        unsafe {
            std::env::set_var("SUDO_USER", "");
        }
        unsafe {
            std::env::set_var("USER", "bob");
        }
        let user = resolve_user(&None).unwrap();
        assert_eq!(user, "bob");
    }

    #[test]
    fn test_verify_user_exists_fails_for_nonexistent() {
        let r = verify_user_exists("__nonexistent_user_xyz__");
        assert!(r.is_err());
    }
}
