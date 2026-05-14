use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;

use crate::{sdebug, sinfo};

const ZSH_DIR: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/.zsh");

const SOURCE_BLOCK_BEGIN: &str = "# add by source_shrc";
const SOURCE_BLOCK_END: &str = "# end by source_shrc";

const SOURCE_BLOCK: &str = r#"# add by source_shrc
mnt="__ZSH_DIR__"
if [[ -d "$mnt" ]]; then
    while IFS= read -r -d '' f; do
        source "$f"
    done < <(find "$mnt" -type f -name '*.zsh' -print0)
fi
# end by source_shrc
"#;

fn zshrc_path() -> anyhow::Result<PathBuf> {
    let home = std::env::var("HOME")
        .or_else(|_| std::env::var("SUDO_HOME"))
        .map_err(|_| anyhow::anyhow!("cannot determine HOME directory"))?;

    let sudo_user = std::env::var("SUDO_USER").ok();
    let target = if let Some(ref user) = sudo_user {
        let dir = format!("/home/{user}");
        if PathBuf::from(&dir).exists() {
            PathBuf::from(&dir)
        } else {
            PathBuf::from(&home)
        }
    } else {
        PathBuf::from(&home)
    };

    Ok(target.join(".zshrc"))
}

fn read_or_create(path: &PathBuf) -> anyhow::Result<String> {
    if path.exists() {
        fs::read_to_string(path)
            .map_err(|e| anyhow::anyhow!("failed to read {}: {e}", path.display()))
    } else {
        Ok(String::new())
    }
}

fn strip_source_block(content: &str) -> String {
    let mut result = String::new();
    let mut in_block = false;

    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed == SOURCE_BLOCK_BEGIN {
            in_block = true;
            continue;
        }
        if in_block {
            if trimmed == SOURCE_BLOCK_END {
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

fn source_block() -> String {
    SOURCE_BLOCK.replace("__ZSH_DIR__", ZSH_DIR)
}

pub fn run(rc_file: Option<String>) -> anyhow::Result<()> {
    sdebug!("zshrc rc_file={:?}", rc_file);

    let path = match rc_file {
        Some(f) => PathBuf::from(f),
        None => zshrc_path()?,
    };

    sdebug!("zshrc path={}", path.display());

    let content = read_or_create(&path)?;
    let cleaned = strip_source_block(&content);
    let mut output = String::new();
    output.push_str(&cleaned);
    output.push_str(&source_block());

    let mut file = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .open(&path)?;

    file.write_all(output.as_bytes())?;
    sinfo!(
        "zshrc configured at {} (zsh_dir={})",
        path.display(),
        ZSH_DIR
    );
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_source_block_no_block() {
        let input = "alias foo='bar'\n";
        assert_eq!(strip_source_block(input), input);
    }

    #[test]
    fn test_strip_source_block_with_block() {
        let block = format!("{}\nsome content\n{}", SOURCE_BLOCK_BEGIN, SOURCE_BLOCK_END);
        let input = format!("alias foo='bar'\n{}\nalias baz='qux'\n", block);
        let expected = "alias foo='bar'\nalias baz='qux'\n";
        assert_eq!(strip_source_block(&input), expected);
    }

    #[test]
    fn test_strip_source_block_empty() {
        assert_eq!(strip_source_block(""), "\n");
    }

    #[test]
    fn test_strip_source_block_only_block() {
        let input = format!(
            "{}\nsome content\n{}\n",
            SOURCE_BLOCK_BEGIN, SOURCE_BLOCK_END
        );
        assert_eq!(strip_source_block(&input), "\n");
    }

    #[test]
    fn test_source_block_contains_zsh_dir() {
        let block = source_block();
        assert!(block.contains(ZSH_DIR));
    }

    #[test]
    fn test_source_block_has_markers() {
        let block = source_block();
        assert!(block.starts_with(SOURCE_BLOCK_BEGIN));
        assert!(block.trim_end().ends_with(SOURCE_BLOCK_END));
    }
}
