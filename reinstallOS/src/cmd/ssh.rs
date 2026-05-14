//! SSH 密钥生成
//!
//! 生成 ed25519 SSH 密钥对并启动 ssh-agent。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | SshConfig.email | | Option<String> | 密钥注释邮箱，None 则跳过注释 |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 run(email) ->
//! 2    |- resolve_key_path ~/.ssh/id_ed25519
//! 3    |- 检查密钥是否已存在，存在则跳过
//! 4    +- ssh-keygen -t ed25519 -C <email> -f <path> -N ""
//! 5    +- eval $(ssh-agent) 启动 agent
//! 6    +- ssh-add <path>
//! 返回 -> Ok(())

use crate::{run_cmd, sdebug, sinfo, swarn};
use std::path::PathBuf;

/// SSH 密钥配置
pub struct SshConfig {
    /// 密钥注释邮箱
    pub email: Option<String>,
}

impl SshConfig {
    pub fn new(email: Option<String>) -> Self {
        Self { email }
    }
}

/// 生成 SSH 密钥并启动 ssh-agent
pub fn run(email: Option<String>) -> anyhow::Result<()> {
    let config = SshConfig::new(email);
    sdebug!("ssh config email={:?}", config.email);

    let key_path = ssh_key_path()?;
    if key_path.exists() {
        swarn!("SSH key already exists at {}", key_path.display());
        return Ok(());
    }

    std::fs::create_dir_all(key_path.parent().unwrap())?;

    let key_str = key_path.to_string_lossy().to_string();
    let mut args = vec!["-t", "ed25519", "-f", &key_str, "-N", ""];
    if let Some(ref email) = config.email {
        args.push("-C");
        args.push(email);
    }

    run_cmd::execute_and_wait(&run_cmd::RunConfig::new("ssh-keygen", &args))?;
    sinfo!("SSH key generated at {}", key_path.display());
    Ok(())
}

fn ssh_key_path() -> anyhow::Result<PathBuf> {
    let home = std::env::var("HOME").map_err(|_| anyhow::anyhow!("$HOME not set"))?;
    Ok(PathBuf::from(home).join(".ssh/id_ed25519"))
}

/// 将项目目录链接到家目录
///
/// 使用 sf_link_mk::link_to 将项目子目录软链到 $HOME 下。
/// ============================
/// 入参说明
/// | 入参 | 参数 | 类型 | 说明 |
/// |------|------|------|------|
/// | dir_name | | &str | 文件夹名，如 "fcitx5" |
/// | 返回 | | Result<()> | Ok(()) |
/// =============================

pub fn link_project_dir_to_home(dir_name: &str) -> anyhow::Result<()> {
    let src = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join(dir_name);
    if !src.exists() {
        swarn!("{} not found in project root, skipping", dir_name);
        return Ok(());
    }
    let home = std::env::var("HOME").map_err(|_| anyhow::anyhow!("$HOME not set"))?;
    let dst = std::path::PathBuf::from(&home).join(dir_name);
    crate::sf_link_mk::link_to(&src, &dst)
}

#[macro_export]
macro_rules! link_home_dir {
    ($dir:expr) => {
        $crate::cmd::ssh::link_project_dir_to_home($dir)
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ssh_config_new_with_email() {
        let cfg = SshConfig::new(Some("a@b.com".into()));
        assert_eq!(cfg.email, Some("a@b.com".to_string()));
    }

    #[test]
    fn test_ssh_config_new_none() {
        let cfg = SshConfig::new(None);
        assert_eq!(cfg.email, None);
    }

    #[test]
    fn test_ssh_key_path_format() {
        let p = ssh_key_path().unwrap();
        assert!(p.ends_with(".ssh/id_ed25519"));
    }

    #[test]
    fn test_link_project_dir_to_home_skip_nonexistent() {
        let result = link_project_dir_to_home("__nonexistent_xyz__");
        assert!(result.is_ok());
    }

    #[test]
    fn test_link_project_dir_to_home_exists() {
        let project_root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"));
        let test_dir_name = "__link_test_dir__";
        let test_dir = project_root.join(test_dir_name);
        std::fs::create_dir_all(&test_dir).unwrap();

        let result = link_project_dir_to_home(test_dir_name);
        assert!(result.is_ok());

        std::fs::remove_dir_all(&test_dir).unwrap();
        let home = std::env::var("HOME").unwrap();
        let dst = std::path::PathBuf::from(&home).join(test_dir_name);
        if dst.is_symlink() || dst.exists() {
            std::fs::remove_file(&dst).unwrap_or_default();
            std::fs::remove_dir_all(&dst).unwrap_or_default();
        }
        let bak = std::path::PathBuf::from(&home).join(format!("{}.bak", test_dir_name));
        std::fs::remove_dir_all(&bak).unwrap_or_default();
    }
}
