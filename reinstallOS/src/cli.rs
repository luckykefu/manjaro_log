use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(
    name = "reinstall_os",
    version,
    about = "Manjaro/Arch Linux post-install system setup"
)]
pub struct Cli {
    #[arg(short = 'n', long, help = "Simulate execution without making changes")]
    pub dry_run: bool,

    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Debug, Subcommand)]
pub enum Commands {
    Theme,
    SudoNopassword,
    Mirrors,
    Fstrim,
    Timezone {
        tz: Option<String>,
    },
    Chown,
    Display {
        output: String,
        rate: String,
    },
    Ssh {
        email: Option<String>,
    },
    Gpg {
        name: String,
        email: String,
    },
    Git {
        #[arg(long)]
        name: Option<String>,
        #[arg(long)]
        email: Option<String>,
    },
    Zshrc {
        rc_file: Option<String>,
    },
    Packages,
    Aur,
    Fcitx5,
    Autostart {
        apps: Vec<String>,
    },
    Update,
    Shadowsocks {
        ip: String,
        #[arg(long, help = "Full deploy (server + local)")]
        deploy: bool,
        #[arg(long, help = "Local proxy config only")]
        local: bool,
    },
    PacmanCfg,
}
