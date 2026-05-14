//! Fcitx5 输入法安装与配置
//!
//! 安装 fcitx5 包、配置 Wayland 输入法、部署配置软链接。
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | run  |      | fn   | 安装+配置+部署 |
//! | 返回 |      | Result<()> | 全部完成 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 install_packages() -> pacman -S fcitx5 fcitx5-*
//! 2 configure_wayland() -> kwriteconfig6
//! 3 link_config() -> sf_link_mk::link_to
//! 返回 -> Ok(())

use crate::run_cmd::{self, RunConfig};
use crate::sinfo;

const FCITX5_PKGS: &[&str] = &[
    "fcitx5",
    "fcitx5-gtk",
    "fcitx5-qt",
    "fcitx5-configtool",
    "fcitx5-chinese-addons",
    "fcitx5-pinyin-zhwiki",
];

fn install_packages() -> anyhow::Result<()> {
    sinfo!("installing fcitx5 packages");
    let mut args = vec!["pacman", "-S", "--needed", "--noconfirm"];
    args.extend_from_slice(FCITX5_PKGS);
    run_cmd::execute_and_wait(&RunConfig::new("sudo", &args))
}

fn configure_wayland() -> anyhow::Result<()> {
    sinfo!("configuring Wayland input method");
    run_cmd::execute_and_wait(&RunConfig::new(
        "kwriteconfig6",
        &[
            "--file",
            "kwinrc",
            "--group",
            "Wayland",
            "--key",
            "InputMethod",
            "/usr/share/applications/org.fcitx.Fcitx5.desktop",
        ],
    ))
}

fn link_config() -> anyhow::Result<()> {
    let src = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("fcitx5");
    let home = std::env::var("HOME").map_err(|_| anyhow::anyhow!("$HOME not set"))?;
    let dst = std::path::PathBuf::from(&home).join(".config/fcitx5");
    crate::sf_link_mk::link_to(&src, &dst)
}

pub fn run() -> anyhow::Result<()> {
    install_packages()?;
    configure_wayland()?;
    link_config()?;
    sinfo!("fcitx5 setup complete");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fcitx5_pkgs_not_empty() {
        assert!(!FCITX5_PKGS.is_empty());
    }

    #[test]
    fn test_fcitx5_pkgs_no_duplicates() {
        let mut v: Vec<&str> = FCITX5_PKGS.to_vec();
        v.sort();
        assert!(!v.windows(2).any(|w| w[0] == w[1]));
    }
}
