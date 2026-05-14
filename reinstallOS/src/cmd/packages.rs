use crate::run_cmd::{self, RunConfig};
use crate::sinfo;

const BASE_PKG: &[&str] = &[
    "base-devel",
    "yay",
    "keepassxc",
    "rust",
    "zed",
    "opencode",
    "wezterm",
    "alacritty",
];

const FONTS_PKG: &[&str] = &[
    "inter-font",
    "adobe-source-han-sans-otc-fonts",
    "adobe-source-han-serif-otc-fonts",
    "noto-fonts",
    "noto-fonts-cjk",
    "noto-fonts-emoji",
    "ttf-dejavu",
    "ttf-liberation",
    "wqy-microhei",
    "wqy-zenhei",
    "adobe-source-han-sans-cn-fonts",
    "adobe-source-han-serif-cn-fonts",
    "ttf-fira-code",
    "ttf-roboto",
];

const SHELL_TOOLS_PKG: &[&str] = &["ripgrep", "dust"];

fn install_group(name: &str, pkgs: &[&str]) -> anyhow::Result<()> {
    sinfo!("installing {} ({} packages)", name, pkgs.len());
    let mut args = vec!["pacman", "-S", "--noconfirm", "--needed"];
    args.extend_from_slice(pkgs);
    run_cmd::execute_and_wait(&RunConfig::new("sudo", &args))
}

pub fn run() -> anyhow::Result<()> {
    install_group("base_pkg", BASE_PKG)?;
    install_group("fonts_pkg", FONTS_PKG)?;
    install_group("shell_tools_pkg", SHELL_TOOLS_PKG)?;
    sinfo!("all packages installed");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base_pkg_not_empty() {
        assert!(!BASE_PKG.is_empty());
    }

    #[test]
    fn test_fonts_pkg_not_empty() {
        assert!(!FONTS_PKG.is_empty());
    }

    #[test]
    fn test_shell_tools_pkg_not_empty() {
        assert!(!SHELL_TOOLS_PKG.is_empty());
    }

    #[test]
    fn test_no_duplicates_within_groups() {
        fn has_dup(slice: &[&str]) -> bool {
            let mut v: Vec<&str> = slice.to_vec();
            v.sort();
            v.windows(2).any(|w| w[0] == w[1])
        }
        assert!(!has_dup(BASE_PKG));
        assert!(!has_dup(FONTS_PKG));
        assert!(!has_dup(SHELL_TOOLS_PKG));
    }
}
