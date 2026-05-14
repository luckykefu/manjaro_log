//! 通用 KDE 配置(字体/输入/KWin/KRunner/锁屏等)
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | 返回 |      | Result<()> | 配置结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 字体 -> kdeglobals General/WM
//! 2 输入 -> kcminputrc Libinput/Keyboard
//! 3 KWin -> kwinrc Effects/ElectricBorders/TabBox/Plugins
//! 4 锁屏 -> kscreenlockerrc Daemon
//! 5 活动管理 -> kactivitymanagerd-pluginsrc
//! 6 KRunner -> krunnerrc General FreeFloating
//! 返回 ->

use crate::exec;
use crate::{sdebug, sinfo};
use anyhow::Result;

const FONT: &str = "Source Han Sans CN,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
const FONT_TITLE: &str = "Source Han Sans CN,10,-1,5,316,0,0,0,0,0,0,0,0,0,0,1,Normal";

/// 通用 KDE 配置
pub fn config_kde_general() -> Result<()> {
    sdebug!("config_kde_general start");

    config_fonts()?;
    config_input()?;
    config_kwin()?;
    config_screenlocker()?;
    config_activities()?;
    config_krunner()?;

    sinfo!("kde general config applied");
    Ok(())
}

/// 字体配置
fn config_fonts() -> Result<()> {
    let f = |file: &str, group: &str, key: &str, val: &str| {
        let cmd = format!(
            "kwriteconfig6 --file {} --group {} --key {} '{}'",
            file, group, key, val
        );
        exec::bash_exec(&cmd)
    };

    f("kdeglobals", "General", "font", FONT_TITLE)?;
    f("kdeglobals", "General", "menuFont", FONT)?;
    f(
        "kdeglobals",
        "General",
        "smallestReadableFont",
        "Source Han Sans CN,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1",
    )?;
    f("kdeglobals", "General", "toolBarFont", FONT)?;
    f("kdeglobals", "General", "fixed", FONT)?;
    f("kdeglobals", "WM", "activeFont", FONT)?;

    sdebug!("fonts configured");
    Ok(())
}

/// 输入设备配置(鼠标加速/数字键盘)
fn config_input() -> Result<()> {
    exec::bash_exec(
        "kwriteconfig6 --file kcminputrc --group Libinput \
         --group 4152 --group 5898 \
         --group 'SteelSeries SteelSeries Rival 100 Dell China' \
         --key PointerAcceleration 1",
    )?;
    exec::bash_exec("kwriteconfig6 --file kcminputrc --group Keyboard --key NumLock 0")?;
    sdebug!("input configured");
    Ok(())
}

/// KWin 特效/边框操作/窗口切换/插件
fn config_kwin() -> Result<()> {
    let k = |group: &str, key: &str, val: &str| {
        let cmd = format!(
            "kwriteconfig6 --file kwinrc --group {} --key {} {}",
            group, key, val
        );
        exec::bash_exec(&cmd)
    };

    k("Effect-overview", "BorderActivate", "1,7")?;
    k("ElectricBorders", "BottomLeft", "KRunner")?;
    k("ElectricBorders", "TopLeft", "ApplicationLauncher")?;
    k("TabBox", "LayoutName", "big_icons")?;

    let plugins: [(&str, &str); 13] = [
        ("mouseclickEnabled", "true"),
        ("trackmouseEnabled", "true"),
        ("contrastEnabled", "true"),
        ("blurEnabled", "true"),
        ("fallapartEnabled", "false"),
        ("mousemarkEnabled", "true"),
        ("translucencyEnabled", "true"),
        ("wobblywindowsEnabled", "true"),
        ("magiclampEnabled", "true"),
        ("squashEnabled", "false"),
        ("diminactiveEnabled", "true"),
        ("glideEnabled", "true"),
        ("scaleEnabled", "false"),
    ];
    for (key, val) in &plugins {
        let cmd = format!(
            "kwriteconfig6 --file kwinrc --group Plugins --key {} {}",
            key, val
        );
        exec::bash_exec(&cmd)?;
    }

    sdebug!("kwin configured");
    Ok(())
}

/// 锁屏配置
fn config_screenlocker() -> Result<()> {
    let cmd = |key: &str, val: &str| {
        exec::bash_exec(&format!(
            "kwriteconfig6 --file kscreenlockerrc --group Daemon --key {} {}",
            key, val
        ))
    };

    cmd("Timeout", "0")?;
    cmd("LockGrace", "900")?;
    cmd("RequirePassword", "false")?;
    cmd("Autolock", "false")?;

    sdebug!("screenlocker configured");
    Ok(())
}

/// 活动管理
fn config_activities() -> Result<()> {
    exec::bash_exec(
        "kwriteconfig6 --file kactivitymanagerd-pluginsrc \
         --group Plugin-org.kde.ActivityManager.Resources.Scoring \
         --key keep-history-for 1",
    )?;
    sdebug!("activities configured");
    Ok(())
}

/// KRunner 悬浮
fn config_krunner() -> Result<()> {
    exec::bash_exec(
        "kwriteconfig6 --file krunnerrc --group General --key FreeFloating --type bool true",
    )?;
    sdebug!("krunner configured");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_kde_general_no_panic() {
        let _ = config_kde_general();
    }
}
