### 关联文件
- file://src/main.rs
- file://src/lib.rs
- file://src/config.rs
- file://src/exec.rs
- file://src/slog.rs
- file://src/theme.rs
- file://src/clock.rs
- file://src/wallpaper.rs
- file://src/general.rs

### 功能解释

KDE Plasma 桌面环境自动配置工具：
- 安装 WhiteSur Mac 风格主题和图标（优先使用本地仓库）
- 配置时钟显示秒数
- 配置壁纸和模糊效果
- 通用 KDE 配置（KWin 合成、KRunner 悬浮、Dolphin 全路径、Konsole 隐藏菜单栏）

### 入参说明

| 入参 | 参数 | 类型 | 说明 |
| ---- | ---- | ---- | ---- |
| CLI 第一参数 | module | String | 执行模块: all, theme, clock, wallpaper, general |
| 环境变量 | KDE_CFG_PROJECT_ROOT | String | 项目根目录 (默认编译时 CARGO_MANIFEST_DIR) |
| 环境变量 | KDE_CFG_PROXY | String | SOCKS5 代理地址 (默认 socks5://127.0.0.1:1080) |
| 环境变量 | KDE_CFG_WHITESUR_KDE_REPO | String | WhiteSur KDE 主题仓库 URL |
| 环境变量 | KDE_CFG_WHITESUR_ICON_REPO | String | WhiteSur 图标仓库 URL |
| 环境变量 | KDE_CFG_WALLPAPER | String | 壁纸文件路径 |
| 环境变量 | KDE_CFG_DEBUG | any | 设置后启用 DEBUG 日志级别 |

### ASCII图示处理逻辑

```
1 CLI 参数解析 -> main:
  读取 argv[1] 确定模块 (默认 all)
  读取 KDE_CFG_DEBUG 设置日志级别
2 加载配置 -> KdeConfig::from_env:
  读取环境变量覆盖默认值
3 执行模块 -> run_module:
  "theme"    -> theme::install_mac_themes
                  ├ WhiteSur 主题已安装? -> 跳过
                  ├ $project_root/WhiteSur-kde 存在? -> 直接 install.sh
                  └ 不存在 -> git clone -> install.sh
                  ├ WhiteSur 图标已安装? -> 跳过
                  ├ $project_root/WhiteSur-icon-theme 存在? -> 直接 install.sh
                  └ 不存在 -> git clone -> install.sh
  "clock"    -> clock::config_kde_clock
                  ├ kwriteconfig6 kded5rc Module-clock autoload true
                  └ kwriteconfig6 clock Clock ShowSeconds true
  "wallpaper"-> wallpaper::config_kde_wallpaper
                  ├ kwriteconfig6 kwinrc Plugins blurEnabled true
                  └ plasma-apply-wallpaperimage (非致命)
  "general"  -> general::config_kde_general
                  ├ KWin 合成
                  ├ KRunner 悬浮
                  ├ Dolphin 全路径
                  └ Konsole 隐藏菜单栏
  "all"      -> 依次执行以上所有
返回 ->
```
