//! AUR 包安装
//!
//! 使用 yay 安装 AUR 包。
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | run  |      | fn   | 安装预定义 AUR 包列表 |
//! | 返回 |      | Result<()> | 安装成功 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 定义 AUR_PKGS 包列表
//! 2 run() -> yay -S --noconfirm --needed <pkgs...>
//! 返回 -> Ok(())

use crate::run_cmd::{self, RunConfig};
use crate::sinfo;

const AUR_PKGS: &[&str] = &["cryptomator-bin"];

/// 安装所有预定义 AUR 包
pub fn run() -> anyhow::Result<()> {
    sinfo!("installing {} AUR packages", AUR_PKGS.len());
    let mut args = vec!["-S", "--noconfirm", "--needed"];
    args.extend_from_slice(AUR_PKGS);
    run_cmd::execute_and_wait(&RunConfig::new("yay", &args))?;
    sinfo!("AUR packages installed");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_aur_pkgs_not_empty() {
        assert!(!AUR_PKGS.is_empty());
    }

    #[test]
    fn test_aur_pkgs_no_duplicates() {
        let mut v: Vec<&str> = AUR_PKGS.to_vec();
        v.sort();
        assert!(!v.windows(2).any(|w| w[0] == w[1]));
    }

    #[test]
    fn test_aur_pkgs_all_have_bin_suffix() {
        for pkg in AUR_PKGS {
            assert!(pkg.ends_with("-bin"), "{pkg} should end with -bin");
        }
    }
}
