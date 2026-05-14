//! 自启动应用配置
//!
//! 将指定应用的 .desktop 文件软链到 ~/.config/autostart/ 实现开机自启。
//! 支持 which 模糊查找：传入 clash-verge 自动匹配 Clash Verge.desktop。
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | apps |      | &[String] | 应用名列表，如 ["fcitx5"] |
//! | 返回 |      | Result<()> | 全部完成 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 run(apps) ->
//! 2    |- apps 为空? -> return
//! 3    |- mkdir ~/.config/autostart
//! 4    +- for app in apps:
//! 5       |- find_desktop(app) -> Option<PathBuf>
//! 6       |- 未找到? -> warn + skip
//! 7       +- sf_link_mk::link_to(src, dst)
//! 返回 -> Ok(())
//!
//! 8 find_desktop(app) ->
//! 9    |- 精确匹配 /usr/share/applications/{app}.desktop? -> return
//! 10   +- 遍历 /usr/share/applications/*.desktop
//! 11      |- match 文件名（去扩展名）包含 app（忽略大小写）
//! 12      +- return 第一个匹配

use std::path::PathBuf;

use crate::sf_link_mk;
use crate::{sinfo, swarn};

const AUTOSTART_DIR: &str = ".config/autostart";
const APPS_DIR: &str = "/usr/share/applications";

fn normalize(s: &str) -> String {
    s.to_lowercase()
        .chars()
        .filter(|c| c.is_alphanumeric())
        .collect()
}

fn find_desktop(app: &str) -> Option<PathBuf> {
    let exact = PathBuf::from(APPS_DIR).join(format!("{app}.desktop"));
    if exact.exists() {
        return Some(exact);
    }

    let app_norm = normalize(app);
    let dir = std::fs::read_dir(APPS_DIR).ok()?;
    for entry in dir.flatten() {
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) != Some("desktop") {
            continue;
        }
        let stem_norm = path.file_stem()?.to_string_lossy().to_lowercase();
        let stem_norm: String = stem_norm.chars().filter(|c| c.is_alphanumeric()).collect();
        if stem_norm.contains(&app_norm) {
            return Some(path);
        }
    }

    None
}

pub fn run(apps: &[String]) -> anyhow::Result<()> {
    if apps.is_empty() {
        swarn!("no apps provided for autostart");
        return Ok(());
    }

    let home = std::env::var("HOME").map_err(|_| anyhow::anyhow!("$HOME not set"))?;
    let autostart_dir = PathBuf::from(&home).join(AUTOSTART_DIR);
    std::fs::create_dir_all(&autostart_dir)?;

    for app in apps {
        let src = match find_desktop(app) {
            Some(p) => p,
            None => {
                swarn!("desktop file not found for: {app}");
                continue;
            }
        };
        let dst = autostart_dir.join(src.file_name().unwrap());
        sf_link_mk::link_to(&src, &dst)?;
    }

    sinfo!("autostart configured for {} app(s)", apps.len());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_empty_apps() {
        let result = run(&[]);
        assert!(result.is_ok());
    }
}
