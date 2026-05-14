//! KDE 配置结构体
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! |      | project_root | String | Cargo.toml 所在目录 |
//! |      | proxy | String | SOCKS5 代理地址 |
//! |      | lookandfeel_theme | String | 全局主题名称 |
//! |      | cursor_theme | String | 光标主题名称 |
//! |      | whitesur_kde_repo | String | WhiteSur KDE 主题仓库 |
//! |      | whitesur_icon_repo | String | WhiteSur 图标仓库 |
//! |      | whitesur_cursors_repo | String | WhiteSur 光标仓库 |
//! |      | wallpaper_path | String | 壁纸文件路径 |
//! | 返回 | KdeConfig | | 配置实例 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 读取环境变量 -> KdeConfig::from_env:
//!   检查 KDE_CFG_PROJECT_ROOT / KDE_CFG_PROXY / KDE_CFG_LOOKANDFEEL_THEME
//!   / KDE_CFG_CURSOR_THEME / KDE_CFG_WHITESUR_*_REPO / KDE_CFG_WALLPAPER
//!   缺失项使用 Default 值
//! 返回 ->

use crate::sdebug;
use std::env;

/// KDE 配置
#[derive(Debug, Clone)]
pub struct KdeConfig {
    /// Cargo.toml 所在目录,默认编译时 CARGO_MANIFEST_DIR
    pub project_root: String,
    /// SOCKS5 代理地址,默认 socks5://127.0.0.1:1080
    pub proxy: String,
    /// KDE 全局主题名称,默认 com.github.vinceliuice.WhiteSur-dark
    pub lookandfeel_theme: String,
    /// 光标主题名称,默认 WhiteSur-cursors
    pub cursor_theme: String,
    /// WhiteSur KDE 主题 Git 仓库 URL
    pub whitesur_kde_repo: String,
    /// WhiteSur 图标主题 Git 仓库 URL
    pub whitesur_icon_repo: String,
    /// WhiteSur 光标主题 Git 仓库 URL
    pub whitesur_cursors_repo: String,
    /// 壁纸文件路径
    pub wallpaper_path: String,
}

impl Default for KdeConfig {
    fn default() -> Self {
        Self {
            project_root: env!("CARGO_MANIFEST_DIR").to_string(),
            proxy: "socks5://127.0.0.1:1080".into(),
            lookandfeel_theme: "com.github.vinceliuice.WhiteSur-dark".into(),
            cursor_theme: "WhiteSur-cursors".into(),
            whitesur_kde_repo: "https://github.com/vinceliuice/WhiteSur-kde".into(),
            whitesur_icon_repo: "https://github.com/vinceliuice/WhiteSur-icon-theme".into(),
            whitesur_cursors_repo: "https://github.com/vinceliuice/WhiteSur-cursors".into(),
            wallpaper_path: format!("{}/.local/share/wallpapers/default.jpg", home_dir()),
        }
    }
}

impl KdeConfig {
    /// 从环境变量加载配置,缺失项使用默认值
    pub fn from_env() -> Self {
        let mut cfg = Self::default();
        if let Ok(v) = env::var("KDE_CFG_PROJECT_ROOT") {
            cfg.project_root = v;
        }
        if let Ok(v) = env::var("KDE_CFG_PROXY") {
            cfg.proxy = v;
        }
        if let Ok(v) = env::var("KDE_CFG_LOOKANDFEEL_THEME") {
            cfg.lookandfeel_theme = v;
        }
        if let Ok(v) = env::var("KDE_CFG_CURSOR_THEME") {
            cfg.cursor_theme = v;
        }
        if let Ok(v) = env::var("KDE_CFG_WHITESUR_KDE_REPO") {
            cfg.whitesur_kde_repo = v;
        }
        if let Ok(v) = env::var("KDE_CFG_WHITESUR_ICON_REPO") {
            cfg.whitesur_icon_repo = v;
        }
        if let Ok(v) = env::var("KDE_CFG_WHITESUR_CURSORS_REPO") {
            cfg.whitesur_cursors_repo = v;
        }
        if let Ok(v) = env::var("KDE_CFG_WALLPAPER") {
            cfg.wallpaper_path = v;
        }
        sdebug!("KdeConfig: {:?}", cfg);
        cfg
    }
}

fn home_dir() -> String {
    env::var("HOME").unwrap_or_else(|_| "/tmp".into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_proxy() {
        let cfg = KdeConfig::default();
        assert!(cfg.proxy.contains("socks5://"));
    }

    #[test]
    fn test_default_repos() {
        let cfg = KdeConfig::default();
        assert!(cfg.whitesur_kde_repo.contains("github.com"));
        assert!(cfg.whitesur_icon_repo.contains("github.com"));
        assert!(cfg.whitesur_cursors_repo.contains("github.com"));
    }

    #[test]
    fn test_default_lookandfeel() {
        let cfg = KdeConfig::default();
        assert!(cfg.lookandfeel_theme.contains("WhiteSur"));
    }

    #[test]
    fn test_default_cursor() {
        let cfg = KdeConfig::default();
        assert!(cfg.cursor_theme.contains("WhiteSur"));
    }

    #[test]
    fn test_wallpaper_path_contains_wallpapers() {
        let cfg = KdeConfig::default();
        assert!(cfg.wallpaper_path.contains("wallpapers"));
    }

    #[test]
    fn test_project_root_not_empty() {
        let cfg = KdeConfig::default();
        assert!(!cfg.project_root.is_empty());
    }

    #[test]
    fn test_from_env_uses_defaults_when_no_env() {
        let cfg = KdeConfig::from_env();
        assert!(cfg.proxy.contains("socks5://"));
    }
}
