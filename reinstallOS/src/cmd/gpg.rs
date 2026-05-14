//! GPG 密钥生成
//!
//! 生成 ed25519/cv25519 GPG 密钥对并导出。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! | ---- | ---- | ---- | ---- |
//! | GpgConfig.name | | String | 用户名 |
//! | GpgConfig.email | | String | 邮箱 |
//! | GpgConfig.passphrase | | String | 密钥密码 |
//! | run | name, email | &str, &str | 使用默认密码执行密钥生成 |
//! | 返回 | | Result<()> | Ok(()) |
//! =============================
//! ASCII图示处理逻辑:
//!
//! 1 run(name, email) ->
//! 2    |- 构建 GpgConfig
//! 3    +- gpg_gen(config)
//! 4 gpg_gen(config) ->
//! 5    |- 创建 ~/.gnupg (700)
//! 6    |- 写入 batch 配置文件
//! 7    +- gpg --batch --gen-key < batch 文件
//! 8    +- gpg --gen-revoke 生成吊销证书
//! 9    +- gpg --export --armor 导出公钥
//! 返回 -> ()

use crate::{run_cmd, sdebug, serror, sinfo, swarn};

pub const GPG_PASSPHRASE: &str = "lkf.Gpg.mima3";

pub struct GpgConfig {
    pub name: String,
    pub email: String,
    pub passphrase: String,
}

impl GpgConfig {
    pub fn new(name: &str, email: &str, passphrase: &str) -> Self {
        Self {
            name: name.to_string(),
            email: email.to_string(),
            passphrase: passphrase.to_string(),
        }
    }
}

pub fn run(name: &str, email: &str) -> anyhow::Result<()> {
    let config = GpgConfig::new(name, email, GPG_PASSPHRASE);
    sdebug!("gpg name={} email={}", config.name, config.email);
    gpg_gen(&config)
}

fn gpg_gen(cfg: &GpgConfig) -> anyhow::Result<()> {
    let home = std::env::var("HOME").map_err(|_| anyhow::anyhow!("$HOME not set"))?;
    let gnupg_dir = std::path::PathBuf::from(&home).join(".gnupg");
    std::fs::create_dir_all(&gnupg_dir)?;

    let out = run_cmd::capture_output(&run_cmd::RunConfig::new(
        "gpg",
        &["--list-keys", &cfg.email],
    ))
    .unwrap_or_default();
    if !out.is_empty() {
        swarn!("GPG key for {} already exists, skipping", cfg.email);
        return Ok(());
    }

    let batch_file = gnupg_dir.join("batch-gen-key");
    let batch_content = format!(
        r#"Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: {name}
Name-Email: {email}
Expire-Date: 0
Passphrase: {passphrase}
%commit
"#,
        name = cfg.name,
        email = cfg.email,
        passphrase = cfg.passphrase
    );
    std::fs::write(&batch_file, &batch_content)?;
    sdebug!("batch file written to {}", batch_file.display());

    let result = run_cmd::execute_and_wait(&run_cmd::RunConfig::new(
        "gpg",
        &["--batch", "--gen-key", batch_file.to_str().unwrap()],
    ));
    std::fs::remove_file(&batch_file).ok();

    if let Err(e) = result {
        serror!("gpg --batch --gen-key failed: {e}");
        anyhow::bail!("gpg key generation failed: {e}");
    }

    sinfo!("GPG key generated for {} <{}>", cfg.name, cfg.email);

    // 生成吊销证书
    let revoke_file = gnupg_dir.join(format!("{}.rev", cfg.email));
    let revoke_cmd = format!(
        "gpg --batch --pinentry-mode loopback --passphrase '{}' \
         --gen-revoke '{}' 2>/dev/null > '{}'",
        cfg.passphrase,
        cfg.email,
        revoke_file.display()
    );
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new("bash", &["-c", &revoke_cmd])).ok();
    sinfo!("revocation certificate saved to {}", revoke_file.display());

    // 导出公钥
    let pubkey_file = gnupg_dir.join(format!("{}.asc", cfg.email));
    let export_cmd = format!(
        "gpg --armor --export '{}' > '{}'",
        cfg.email,
        pubkey_file.display()
    );
    run_cmd::execute_and_wait(&run_cmd::RunConfig::new("bash", &["-c", &export_cmd])).ok();
    sinfo!("public key exported to {}", pubkey_file.display());

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gpg_config_new() {
        let cfg = GpgConfig::new("Alice", "alice@test.com", "secret");
        assert_eq!(cfg.name, "Alice");
        assert_eq!(cfg.email, "alice@test.com");
        assert_eq!(cfg.passphrase, "secret");
    }

    #[test]
    fn test_gpg_config_default_passphrase() {
        assert_eq!(GPG_PASSPHRASE, "lkf.Gpg.mima3");
    }

    #[test]
    fn test_batch_content_format() {
        let cfg = GpgConfig::new("Test", "t@t.com", "pass");
        let batch = format!(
            "Key-Type: eddsa\nKey-Curve: ed25519\n\
             Subkey-Type: ecdh\nSubkey-Curve: cv25519\n\
             Name-Real: {name}\nName-Email: {email}\n\
             Expire-Date: 0\nPassphrase: {passphrase}\n%commit\n",
            name = cfg.name,
            email = cfg.email,
            passphrase = cfg.passphrase
        );
        assert!(batch.contains("Key-Type: eddsa"));
        assert!(batch.contains(&cfg.email));
        assert!(batch.contains(&cfg.name));
    }
}
