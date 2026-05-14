use clap::Parser;
use reinstall_os::cli::Cli;

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    reinstall_os::run(cli.command)
}
