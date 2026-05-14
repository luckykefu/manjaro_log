//! 安装 WhiteSur KDE 主题/图标/光标
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | cfg  | &KdeConfig | KDE 配置(project_root,代理,仓库URL) |
//! | 返回 |      | Result<()>  | 安装结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 每项安装（主题/图标/光标）统一流程:
//! 1 确保本地仓库存在 -> ensure_local_repo:
//!   检查 $project_root/<repo_dir> 是否存在
//!   不存在 -> git clone
//! 2 检查已安装? -> target.exists
//!   是 -> 跳过
//!   否 -> run_install: cd 本地仓库 && ./install.sh
//! 返回 ->

use anyhow::{Context, Result};
use std::env;
use std::path::PathBuf;

use crate::config::KdeConfig;
use crate::exec;
use crate::{sdebug, sinfo};

fn home() -> PathBuf {
    PathBuf::from(env::var("HOME").unwrap_or_else(|_| "/tmp".into()))
}

/// 安装所有 WhiteSur 组件
pub fn install_mac_themes(cfg: &KdeConfig) -> Result<()> {
    sdebug!("install_mac_themes start");
    install_whitesur_theme(cfg)?;
    install_whitesur_icons(cfg)?;
    install_whitesur_cursors(cfg)?;
    sinfo!("mac themes all installed");
    Ok(())
}

/// 安装 WhiteSur KDE 主题
fn install_whitesur_theme(cfg: &KdeConfig) -> Result<()> {
    let local_repo = PathBuf::from(&cfg.project_root).join("WhiteSur-kde");
    ensure_local_repo(
        cfg,
        &local_repo,
        &cfg.whitesur_kde_repo,
        "WhiteSur KDE 主题",
    )?;

    let target = home().join(".local/share/plasma/look-and-feel/WhiteSur");
    if target.exists() {
        sinfo!("WhiteSur KDE 主题已安装,跳过");
        return Ok(());
    }

    run_install(&local_repo, "WhiteSur KDE 主题")
}

/// 安装 WhiteSur 图标
fn install_whitesur_icons(cfg: &KdeConfig) -> Result<()> {
    let local_repo = PathBuf::from(&cfg.project_root).join("WhiteSur-icon-theme");
    ensure_local_repo(cfg, &local_repo, &cfg.whitesur_icon_repo, "WhiteSur 图标")?;

    let target = home().join(".local/share/icons/WhiteSur");
    if target.exists() {
        sinfo!("WhiteSur 图标已安装,跳过");
        return Ok(());
    }

    run_install(&local_repo, "WhiteSur 图标")
}

/// 安装 WhiteSur 光标
fn install_whitesur_cursors(cfg: &KdeConfig) -> Result<()> {
    let local_repo = PathBuf::from(&cfg.project_root).join("WhiteSur-cursors");
    ensure_local_repo(
        cfg,
        &local_repo,
        &cfg.whitesur_cursors_repo,
        "WhiteSur 光标",
    )?;

    let target = home().join(".local/share/icons/WhiteSur-cursors");
    if target.exists() {
        sinfo!("WhiteSur 光标已安装,跳过");
        return Ok(());
    }

    run_install(&local_repo, "WhiteSur 光标")
}

/// 确保本地仓库存在,不存在则克隆
fn ensure_local_repo(
    cfg: &KdeConfig,
    local_repo: &PathBuf,
    remote_url: &str,
    name: &str,
) -> Result<()> {
    if local_repo.exists() {
        sdebug!("{} 本地仓库已存在: {}", name, local_repo.display());
        return Ok(());
    }
    sdebug!(
        "{} 本地仓库不存在, 从远程克隆到 {}",
        name,
        local_repo.display()
    );
    let cmd = format!(
        "git clone --depth 1 {} {}",
        remote_url,
        local_repo.display()
    );
    exec::run_with_env(&cmd, &[("ALL_PROXY", &cfg.proxy)])
        .with_context(|| format!("{} 克隆失败", name))?;
    Ok(())
}

/// 从本地仓库执行安装
fn run_install(local_repo: &PathBuf, name: &str) -> Result<()> {
    sdebug!("从本地仓库安装: {}", local_repo.display());
    exec::bash_exec(&format!("cd {} && ./install.sh", local_repo.display()))
        .with_context(|| format!("{} 安装失败", name))?;
    sinfo!("{} 安装完成", name);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_home_not_empty() {
        let h = home();
        assert!(!h.as_os_str().is_empty());
    }
}
