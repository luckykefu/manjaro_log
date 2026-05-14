//! 系统更新
//!
//! 执行系统包和 AUR 包更新。
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | UpdateConfig | | struct | 空结构体（预留） |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 run() ->
//! 2    +- sudo pacman -Syyu --noconfirm
//! 3    +- yay -Syyu --noconfirm
//! 返回 -> Ok(())

use crate::run_cmd::{self, RunConfig};
use crate::{sdebug, sinfo};

pub struct UpdateConfig;

impl UpdateConfig {
    pub fn new() -> Self {
        Self
    }
}

pub fn run() -> anyhow::Result<()> {
    sdebug!("running full update");

    sinfo!("updating system packages");
    run_cmd::execute_and_wait(&RunConfig::new("sudo", &["pacman", "-Syyu", "--noconfirm"]))?;

    sinfo!("updating AUR packages");
    run_cmd::execute_and_wait(&RunConfig::new("yay", &["-Syyu", "--noconfirm"]))?;

    sinfo!("full update complete");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_update_config_new() {
        let cfg = UpdateConfig::new();
        assert_eq!(std::mem::size_of_val(&cfg), 0);
    }
}
