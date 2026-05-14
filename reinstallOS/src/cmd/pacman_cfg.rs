use crate::run_cmd::{self, RunConfig};
use crate::sinfo;

const PACMAN_CONF: &str = "/etc/pacman.conf";

const BLOCK_BEGIN: &str = "# add by pacman_cfg.rs";
const BLOCK_END: &str = "# end add by pacman_cfg";

const ARCHLINUXCN_BLOCK: &str = r#"
# add by pacman_cfg.rs
[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
# end add by pacman_cfg
"#;

fn read_pacman_conf() -> anyhow::Result<String> {
    run_cmd::capture_output(&RunConfig::new("sudo", &["cat", PACMAN_CONF]))
        .map_err(|e| anyhow::anyhow!("failed to read {PACMAN_CONF}: {e}"))
}

fn write_pacman_conf(content: &str) -> anyhow::Result<()> {
    let tmp = std::env::temp_dir().join(format!("pacman_conf_{}", std::process::id()));
    std::fs::write(&tmp, content)?;
    let result = run_cmd::execute_and_wait(&RunConfig::new(
        "sudo",
        &["cp", &tmp.to_string_lossy(), PACMAN_CONF],
    ));
    std::fs::remove_file(&tmp).ok();
    result.map_err(|e| anyhow::anyhow!("failed to write {PACMAN_CONF}: {e}"))
}

fn strip_block(content: &str) -> String {
    let mut result = String::new();
    let mut in_block = false;

    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == BLOCK_BEGIN {
            in_block = true;
            continue;
        }
        if in_block {
            if trimmed == BLOCK_END {
                in_block = false;
            }
            continue;
        }
        result.push_str(line);
        result.push('\n');
    }

    while result.ends_with('\n') {
        result.pop();
    }
    result.push('\n');

    result
}

fn install_archlinuxcn() -> anyhow::Result<()> {
    sinfo!("updating package databases");
    run_cmd::execute_and_wait(&RunConfig::new("sudo", &["pacman", "-Syy", "--noconfirm"]))?;

    sinfo!("installing archlinuxcn-keyring");
    run_cmd::execute_and_wait(&RunConfig::new(
        "sudo",
        &["pacman", "-S", "--noconfirm", "archlinuxcn-keyring"],
    ))?;

    Ok(())
}

fn has_archlinuxcn(content: &str) -> bool {
    content.contains("[archlinuxcn]")
}

pub fn run() -> anyhow::Result<()> {
    let raw = read_pacman_conf()?;

    if has_archlinuxcn(&raw) {
        sinfo!("archlinuxcn repo already in {PACMAN_CONF}, skipping add");
    } else {
        let cleaned = strip_block(&raw);
        let mut output = String::new();
        output.push_str(&cleaned);
        output.push_str(ARCHLINUXCN_BLOCK);
        write_pacman_conf(&output)?;
        sinfo!("archlinuxcn repo added to {PACMAN_CONF}");
    }

    install_archlinuxcn()?;
    sinfo!("pacman-cfg done");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_block_no_block() {
        let input = "[core]\nServer = ...\n";
        assert_eq!(strip_block(input), input);
    }

    #[test]
    fn test_strip_block_with_block() {
        let block = format!("{}\ncontent\n{}", BLOCK_BEGIN, BLOCK_END);
        let input = format!("[core]\n{block}\n[extra]\n");
        let expected = "[core]\n[extra]\n";
        assert_eq!(strip_block(&input), expected);
    }

    #[test]
    fn test_strip_block_empty() {
        assert_eq!(strip_block(""), "\n");
    }

    #[test]
    fn test_has_archlinuxcn_true() {
        assert!(has_archlinuxcn(
            "[archlinuxcn]\nSigLevel = Optional TrustedOnly\n"
        ));
    }

    #[test]
    fn test_has_archlinuxcn_false() {
        assert!(!has_archlinuxcn("[core]\n[extra]\n"));
    }

    #[test]
    fn test_block_constants() {
        assert!(ARCHLINUXCN_BLOCK.contains(BLOCK_BEGIN));
        assert!(ARCHLINUXCN_BLOCK.contains(BLOCK_END));
        assert!(ARCHLINUXCN_BLOCK.contains("[archlinuxcn]"));
    }
}
