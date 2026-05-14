//! Git 全局配置
//!
//! 配置 Git 全局 user.name 和 user.email。
//! 若当前值已匹配则跳过，避免重复写入。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | GitConfig.name | | String | 用户名 |
//! | GitConfig.email | | String | 邮箱 |
//! | run | name, email | Option<String> | 使用参数或默认值配置 Git |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 run(name, email) ->
//! 2    |- 解析 name: arg ?? default ?? 当前 git config
//! 3    |- 解析 email: arg ?? default ?? 当前 git config
//! 4    |- 跳过已匹配的值, 写入变更的值
//! 5    +- git config --global user.name/email
//! 返回 -> ()

use crate::{run_cmd, sdebug, sinfo};

pub const GIT_NAME: &str = "kefu";
pub const GIT_EMAIL: &str = "19157521820@163.com";

pub struct GitConfig {
    pub name: String,
    pub email: String,
}

impl GitConfig {
    pub fn new(name: &str, email: &str) -> Self {
        Self {
            name: name.to_string(),
            email: email.to_string(),
        }
    }
}

pub fn run(name: Option<String>, email: Option<String>) -> anyhow::Result<()> {
    sdebug!("git name={:?} email={:?}", name, email);

    let resolved_name = resolve_value(name, GIT_NAME, "user.name");
    let resolved_email = resolve_value(email, GIT_EMAIL, "user.email");

    if let Some(ref n) = resolved_name {
        run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
            "git",
            &["config", "--global", "user.name", n],
        ))?;
        sinfo!("git user.name set to {}", n);
    }
    if let Some(ref e) = resolved_email {
        run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
            "git",
            &["config", "--global", "user.email", e],
        ))?;
        sinfo!("git user.email set to {}", e);
    }

    if resolved_name.is_none() && resolved_email.is_none() {
        sinfo!("git config already up-to-date");
    }

    Ok(())
}

fn resolve_value(arg: Option<String>, default: &str, key: &str) -> Option<String> {
    let value = arg.unwrap_or_else(|| default.to_string());

    let current = run_cmd::capture_output(&run_cmd::RunConfig::new(
        "git",
        &["config", "--global", key],
    ))
    .unwrap_or_default();

    if current.trim() == value {
        sdebug!("git {} already set to {}, skipping", key, value);
        return None;
    }

    Some(value)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_git_config_new() {
        let cfg = GitConfig::new("Alice", "alice@t.com");
        assert_eq!(cfg.name, "Alice");
        assert_eq!(cfg.email, "alice@t.com");
    }

    #[test]
    fn test_defaults_const() {
        assert_eq!(GIT_NAME, "kefu");
        assert_eq!(GIT_EMAIL, "19157521820@163.com");
    }

    #[test]
    fn test_resolve_value_arg_takes_priority() {
        let result = resolve_value(Some("custom".into()), "default", "nonexistent.key");
        assert_eq!(result, Some("custom".to_string()));
    }

    #[test]
    fn test_resolve_value_fallsback_to_default() {
        let result = resolve_value(None, "default_val", "nonexistent.key");
        assert_eq!(result, Some("default_val".to_string()));
    }
}
