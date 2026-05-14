//! 配置 KDE 壁纸(必应每日)和模糊效果
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | 返回 |      | Result<()> | 配置结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 启用模糊 -> kwriteconfig6 kwinrc Plugins blurEnabled true
//! 2 解析 plasma-org.kde.plasma.desktop-appletsrc
//!   找到所有桌面 container (location=0, plugin=org.kde.plasma.folder)
//! 3 对每个桌面 container 设置:
//!   wallpaperplugin=org.kde.potd
//!   Wallpaper/org.kde.potd/General/Provider=bing
//! 4 重启 plasmashell
//! 返回 ->

use anyhow::{Context, Result};
use std::env;
use std::fs;
use std::path::PathBuf;

use crate::exec;
use crate::{sdebug, sinfo};

const BUS: &str = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";

fn appletsrc_path() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| "/tmp".into());
    PathBuf::from(home).join(".config/plasma-org.kde.plasma.desktop-appletsrc")
}

/// 配置壁纸+模糊
pub fn config_kde_wallpaper() -> Result<()> {
    sdebug!("config_kde_wallpaper start");

    exec::bash_exec("kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true")?;
    sdebug!("blur enabled");

    let path = appletsrc_path();
    let content =
        fs::read_to_string(&path).with_context(|| format!("读取 {} 失败", path.display()))?;

    let desktop_cids = find_desktop_containments(&content);
    if desktop_cids.is_empty() {
        anyhow::bail!("未找到桌面 container");
    }

    for cid in &desktop_cids {
        set_bing_wallpaper(cid)?;
    }

    sinfo!("kde wallpaper configured ({} desktops)", desktop_cids.len());
    Ok(())
}

/// 解析 appletsrc,返回所有桌面 container ID
/// 桌面 container 特征: location=0, plugin=org.kde.plasma.folder
fn find_desktop_containments(content: &str) -> Vec<String> {
    let mut cids = Vec::new();
    let mut current_cid: Option<String> = None;
    let mut has_location0 = false;
    let mut has_folder = false;

    for line in content.lines() {
        let trimmed = line.trim();

        if let Some(cid) = trimmed.strip_prefix("[Containments][") {
            let cid = cid.split(']').next().unwrap_or("").to_string();
            // 检查是否是新 container 的开始
            if let Some(ref prev) = current_cid {
                if has_location0 && has_folder {
                    cids.push(prev.clone());
                }
            }
            current_cid = Some(cid);
            has_location0 = false;
            has_folder = false;
        } else if let Some(val) = trimmed.strip_prefix("location=") {
            if val.trim() == "0" {
                has_location0 = true;
            }
        } else if let Some(val) = trimmed.strip_prefix("plugin=") {
            if val.trim() == "org.kde.plasma.folder" {
                has_folder = true;
            }
        }
    }

    // 检查最后一个
    if let Some(cid) = current_cid {
        if has_location0 && has_folder {
            cids.push(cid);
        }
    }

    cids
}

/// 设置 Bing 每日壁纸
fn set_bing_wallpaper(cid: &str) -> Result<()> {
    let base = format!(
        "{} kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
         --group Containments --group {}",
        BUS, cid
    );

    exec::bash_exec(&format!("{} --key wallpaperplugin org.kde.potd", base))?;
    exec::bash_exec(&format!(
        "{} --group Wallpaper --group org.kde.potd --group General --key Provider bing",
        base
    ))?;

    sdebug!("desktop [{}] wallpaper set to bing potd", cid);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_find_desktop_containments_empty() {
        assert!(find_desktop_containments("").is_empty());
    }

    #[test]
    fn test_find_desktop_containments_found() {
        let content = "\
[Containments][1]
location=0
plugin=org.kde.plasma.folder
";
        let cids = find_desktop_containments(content);
        assert_eq!(cids, vec!["1"]);
    }

    #[test]
    fn test_find_desktop_containments_skips_panel() {
        let content = "\
[Containments][1]
location=3
plugin=org.kde.plasma.panel
";
        assert!(find_desktop_containments(content).is_empty());
    }

    #[test]
    fn test_find_desktop_containments_multiple() {
        let content = "\
[Containments][1]
location=0
plugin=org.kde.plasma.folder
[Containments][2]
location=3
plugin=org.kde.plasma.panel
[Containments][3]
location=0
plugin=org.kde.plasma.folder
";
        let cids = find_desktop_containments(content);
        assert_eq!(cids, vec!["1", "3"]);
    }
}
