//! Git 全局配置
//!
//! 配置用户名、邮箱、默认分支、credential helper 及 GPG 提交签名。
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | GitConfig.name | | String | 用户名 |
//! | GitConfig.email | | String | 邮箱 |
//! | run | name, email | Option<String> | 使用参数或默认值 |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 run(name, email) ->
//! 2    |- 解析 name/email，写入 git config
//! 3    |- git config --global init.defaultBranch main
//! 4    |- git config --global credential.helper
//! 5    +- 查找 GPG 密钥，启用 commit 签名

use crate::run_cmd::{self, RunConfig};
use crate::{sdebug, sinfo, swarn};

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

fn git_config(key: &str, value: &str) -> anyhow::Result<()> {
    run_cmd::execute_and_wait(&RunConfig::new("git", &["config", "--global", key, value]))
}

fn git_config_get(key: &str) -> String {
    run_cmd::capture_output(&RunConfig::new("git", &["config", "--global", key]))
        .unwrap_or_default()
        .trim()
        .to_string()
}

fn resolve_value(arg: Option<String>, default: &str, key: &str) -> Option<String> {
    let value = arg.unwrap_or_else(|| default.to_string());
    if git_config_get(key) == value {
        sdebug!("git {} already set to {}, skipping", key, value);
        return None;
    }
    Some(value)
}

fn set_user_config(name: Option<String>, email: Option<String>) -> anyhow::Result<()> {
    if let Some(n) = resolve_value(name, GIT_NAME, "user.name") {
        git_config("user.name", &n)?;
        sinfo!("git user.name set to {}", n);
    }
    if let Some(e) = resolve_value(email, GIT_EMAIL, "user.email") {
        git_config("user.email", &e)?;
        sinfo!("git user.email set to {}", e);
    }
    if git_config_get("user.name") == GIT_NAME && git_config_get("user.email") == GIT_EMAIL {
        sinfo!("git user config up-to-date");
    }
    Ok(())
}

fn set_default_branch() -> anyhow::Result<()> {
    if git_config_get("init.defaultBranch") == "main" {
        sdebug!("git init.defaultBranch already main");
        return Ok(());
    }
    git_config("init.defaultBranch", "main")?;
    sinfo!("git init.defaultBranch set to main");
    Ok(())
}

fn set_credential_helper() -> anyhow::Result<()> {
    if git_config_get("credential.helper") == "libsecret" {
        sdebug!("git credential.helper already libsecret");
        return Ok(());
    }
    if git_config("credential.helper", "libsecret").is_err() {
        git_config("credential.helper", "cache --timeout=3600")?;
        swarn!("libsecret unavailable, using cache");
    }
    sinfo!("git credential.helper configured");
    Ok(())
}

fn set_gpg_signing(email: &str) -> anyhow::Result<()> {
    if git_config_get("commit.gpgsign") == "true" {
        sdebug!("git commit.gpgsign already enabled");
        return Ok(());
    }
    let out = run_cmd::capture_output(&RunConfig::new(
        "gpg",
        &["--list-secret-keys", "--keyid-format", "LONG", email],
    ));
    match out {
        Ok(out) => {
            if let Some(line) = out.lines().find(|l| l.trim().starts_with("sec")) {
                if let Some(key) = line
                    .split('/')
                    .nth(1)
                    .and_then(|s| s.split_whitespace().next())
                {
                    git_config("user.signingkey", key)?;
                    git_config("commit.gpgsign", "true")?;
                    sinfo!("gpg signing enabled key={key}");
                }
            }
        }
        Err(_) => {
            swarn!("no gpg key found for {email}, skipping sign config");
        }
    }
    Ok(())
}

pub fn run(name: Option<String>, email: Option<String>) -> anyhow::Result<()> {
    sdebug!("git name={:?} email={:?}", name, email);
    let resolved_email = resolve_value(email.clone(), GIT_EMAIL, "user.email")
        .unwrap_or_else(|| GIT_EMAIL.to_string());

    set_user_config(name, email)?;
    set_default_branch()?;
    set_credential_helper()?;
    set_gpg_signing(&resolved_email)?;

    sinfo!("git full configuration complete");
    Ok(())
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
