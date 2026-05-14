//! 软链接创建工具
//!
//! 备份目标路径并创建软链接。
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | src  |      | &Path | 源路径 |
//! | dst  |      | &Path | 目标路径 |
//! | 返回 |      | Result<()> | 链接创建成功 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 link_to(src, dst) ->
//! 2    |- src 不存在? -> warn + return
//! 3    |- dst 存在? -> rename -> {dst}.bak
//! 4    +- symlink src -> dst
//! 返回 -> ()

use std::path::Path;

use crate::sinfo;

/// 备份目标路径并创建软链接
pub fn link_to(src: &Path, dst: &Path) -> anyhow::Result<()> {
    sinfo!("link_to src={} dst={}", src.display(), dst.display());

    if !src.exists() {
        anyhow::bail!("src not found: {}", src.display());
    }

    if dst.exists() || dst.is_symlink() {
        let bak = std::path::PathBuf::from(format!("{}.bak", dst.display()));
        if bak.exists() || bak.is_symlink() {
            std::fs::remove_dir_all(&bak)
                .or_else(|_| std::fs::remove_file(&bak))
                .ok();
        }
        std::fs::rename(dst, &bak)?;
        sinfo!("backed up {} -> {}", dst.display(), bak.display());
    }

    std::os::unix::fs::symlink(src, dst)?;
    sinfo!("linked {} -> {}", dst.display(), src.display());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_link_to_src_not_exists() {
        let tmp = std::env::temp_dir();
        let src = tmp.join("__test_link_src_nonexistent__");
        let dst = tmp.join("__test_link_dst_nonexistent__");
        let result = link_to(&src, &dst);
        assert!(result.is_err());
    }

    #[test]
    fn test_link_to_create() {
        let tmp = std::env::temp_dir();
        let test_name = format!("__link_test_{}__", std::process::id());
        let src = tmp.join(&test_name);
        let dst = tmp.join(format!("{}_dst", test_name));

        std::fs::write(&src, "test").unwrap();

        let result = link_to(&src, &dst);
        assert!(result.is_ok());
        assert!(dst.is_symlink() || dst.exists());

        std::fs::remove_file(&src).ok();
        std::fs::remove_file(&dst).ok();
    }

    #[test]
    fn test_link_to_backup_existing() {
        let tmp = std::env::temp_dir();
        let test_name = format!("__link_test_bak_{}__", std::process::id());
        let src = tmp.join(&test_name);
        let dst = tmp.join(format!("{}_dst", test_name));
        let bak = tmp.join(format!("{}_dst.bak", test_name));

        std::fs::write(&src, "new").unwrap();
        std::fs::write(&dst, "old").unwrap();

        let result = link_to(&src, &dst);
        assert!(result.is_ok());
        assert!(bak.exists());

        std::fs::remove_file(&src).ok();
        std::fs::remove_file(&dst).ok();
        std::fs::remove_file(&bak).ok();
    }
}
