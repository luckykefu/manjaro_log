pub mod cli;
pub mod cmd;
pub mod run_cmd;
pub mod sf_link_mk;
pub mod slog;

use clap::CommandFactory;
use cli::Commands;

pub fn run(command: Option<Commands>) -> anyhow::Result<()> {
    sdebug!("run command={:?}", command);
    match command {
        None => {
            println!("{}", cli::Cli::command().render_help());
            Ok(())
        }
        Some(c) => dispatch(c),
    }
}

fn dispatch(cmd: Commands) -> anyhow::Result<()> {
    use cmd::*;
    match cmd {
        Commands::Theme => {
            sdebug!("applying theme");
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "lookandfeeltool",
                &["-a", "org.manjaro.breath-dark.desktop"],
            ))?;
            sinfo!("theme applied");
            Ok(())
        }
        Commands::SudoNopassword => {
            sdebug!("configuring passwordless sudo");
            sudo::configure_passwordless_sudo(&sudo::SudoConfig::new(None))?;
            sinfo!("passwordless sudo configured");
            Ok(())
        }
        Commands::Mirrors => {
            sdebug!("setting China mirrors");
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "sudo",
                &["pacman-mirrors", "-c", "China"],
            ))?;
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "sudo",
                &["pacman", "-Sy", "--noconfirm"],
            ))?;
            sinfo!("China mirrors configured");
            Ok(())
        }
        Commands::Fstrim => {
            sdebug!("enabling fstrim timer");
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "sudo",
                &["systemctl", "enable", "fstrim.timer"],
            ))?;
            sinfo!("fstrim.timer enabled");
            Ok(())
        }
        Commands::Timezone { tz } => {
            let tz = tz.unwrap_or_else(|| "UTC".to_string());
            sdebug!("setting timezone to {tz}");
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "sudo",
                &["timedatectl", "set-timezone", &tz],
            ))?;
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "sudo",
                &["timedatectl", "set-ntp", "true"],
            ))?;
            sinfo!("timezone set to {tz}");
            Ok(())
        }
        Commands::Chown => {
            sdebug!("chown /data");
            let user = resolve_current_user()?;
            run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
                "sudo",
                &["chown", "-R", &format!("{user}:{user}"), "/data"],
            ))?;
            sinfo!("/data chowned to {user}");
            Ok(())
        }
        Commands::Display { output, rate } => {
            sdebug!("dispatching display");
            display::set_display_rate(&display::DisplayConfig::new(output, rate))
        }
        Commands::Ssh { email } => ssh::run(email),
        Commands::Gpg { name, email } => gpg::run(&name, &email),
        Commands::Git { name, email } => git::run(name, email),
        Commands::Zshrc { rc_file } => zshrc::run(rc_file),
        Commands::Packages => packages::run(),
        Commands::Aur => aur::run(),
        Commands::Fcitx5 => fcitx5::run(),
        Commands::Autostart { apps } => autostart::run(&apps),
        Commands::Update => update::run(),
        Commands::Shadowsocks { ip, local, .. } => {
            let cfg = shadowsocks::ShadowsocksConfig::new(&ip);
            if local {
                shadowsocks::ss_proxy_config(&cfg)
            } else {
                shadowsocks::deploy_shadowsocks_with(&cfg)
            }
        }
        Commands::PacmanCfg => pacman_cfg::run(),
    }
}

fn resolve_current_user() -> anyhow::Result<String> {
    if let Ok(u) = std::env::var("SUDO_USER") {
        if !u.is_empty() {
            return Ok(u);
        }
    }
    if let Ok(u) = std::env::var("USER") {
        if !u.is_empty() {
            return Ok(u);
        }
    }
    let out = run_cmd::capture_output(&run_cmd::RunConfig::new("whoami", &[]))?;
    if out.is_empty() {
        anyhow::bail!("cannot determine current user");
    }
    Ok(out)
}
