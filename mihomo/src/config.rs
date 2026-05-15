//! 配置生成模块 - 从代理节点列表生成 mihomo 配置文件和 provider YAML
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! |------|------|------|------|
//! |      | proxies | &[Proxy] | 解析后的代理节点列表 |
//! |      | output_dir | &PathBuf | 输出目录路径 |
//! |      | nameserver | &str | DNS 服务器 IP |
//! | 返回 | | Result<()> | 成功或错误 |
//! =============================
//! ASCII 图示处理逻辑:
//!
//! 1. 创建 providers/ 子目录 -> fs::create_dir_all()
//! 2. 生成 provider YAML ->
//!     序列化 proxies -> serde_yaml
//!     写入 providers/my_sub.yaml
//! 3. 生成 config.yaml ->
//!     组装 YAML 字符串 (proxy-providers, proxy-groups, rules, dns)
//!     写入 config.yaml
//! 4. 打印结果路径 -> 返回 Ok(())

use crate::parser::Proxy;
use crate::sinfo;
use anyhow::{Context, Result};
use serde::Serialize;
use std::path::Path;

/// provider YAML 的根结构
#[derive(Serialize)]
struct ProviderFile {
    proxies: Vec<Proxy>,
}

/// 生成完整的 mihomo 配置
///
/// 包含:
/// - providers/my_sub.yaml: 所有代理节点
/// - config.yaml: 主配置 (端口、策略组、规则、DNS)
pub fn generate(proxies: &[Proxy], output_dir: &Path, nameserver: &str) -> Result<()> {
    // 步骤 1: 创建 providers 目录
    let providers_dir = output_dir.join("providers");
    std::fs::create_dir_all(&providers_dir)
        .context(format!("failed to create {}", providers_dir.display()))?;
    sinfo!("[config] created directory: {}", providers_dir.display());

    // 步骤 2: 生成并写入 provider YAML
    let provider_yaml = build_provider_yaml(proxies)?;
    let provider_path = providers_dir.join("my_sub.yaml");
    std::fs::write(&provider_path, &provider_yaml)
        .context(format!("failed to write {}", provider_path.display()))?;
    sinfo!(
        "[config] wrote provider: {} ({} proxies)",
        provider_path.display(),
        proxies.len()
    );

    // 步骤 3: 生成并写入 config.yaml
    let config_yaml = build_config_yaml(nameserver);
    let config_path = output_dir.join("config.yaml");
    std::fs::write(&config_path, &config_yaml)
        .context(format!("failed to write {}", config_path.display()))?;
    sinfo!("[config] wrote config: {}", config_path.display());

    Ok(())
}

/// 构建 provider YAML 内容
fn build_provider_yaml(proxies: &[Proxy]) -> Result<String> {
    let provider = ProviderFile {
        proxies: proxies.to_vec(),
    };
    let yaml = serde_yaml::to_string(&provider).context("failed to serialize proxies to YAML")?;
    Ok(yaml)
}

/// 构建主配置 config.yaml 内容
fn build_config_yaml(nameserver: &str) -> String {
    format!(
        r#"mixed-port: 7897
allow-lan: true
mode: rule
log-level: info
external-controller: 127.0.0.1:9097

proxy-providers:
  my_sub:
    type: file
    path: ./providers/my_sub.yaml
    health-check:
      enable: true
      interval: 300
      url: http://www.gstatic.com/generate_204

proxy-groups:
  - name: proxy
    type: select
    use:
      - my_sub
    proxies:
      - auto
      - DIRECT

  - name: auto
    type: url-test
    use:
      - my_sub
    url: http://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50

rules:
  - DOMAIN-KEYWORD,google,proxy
  - DOMAIN-KEYWORD,youtube,proxy
  - DOMAIN-KEYWORD,github,proxy
  - DOMAIN-KEYWORD,openai,proxy
  - DOMAIN-KEYWORD,telegram,proxy
  - DOMAIN-KEYWORD,twitter,proxy
  - DOMAIN-SUFFIX,cn,DIRECT
  - DOMAIN-KEYWORD,-cn,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,proxy

dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  default-nameserver:
    - {nameserver}
  nameserver:
    - {nameserver}
  fallback:
    - https://doh.pub/dns-query
  fallback-filter:
    geoip: true
    geoip-code: CN
"#,
        nameserver = nameserver
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::Proxy;

    fn make_test_proxies() -> Vec<Proxy> {
        vec![
            Proxy {
                name: "test-vless".into(),
                proxy_type: "vless".into(),
                server: "1.1.1.1".into(),
                port: 443,
                uuid: Some("uuid".into()),
                password: None,
                udp: Some(true),
                flow: None,
                tls: Some(true),
                servername: Some("x.com".into()),
                sni: None,
                client_fingerprint: Some("chrome".into()),
                network: Some("tcp".into()),
                reality_opts: None,
                skip_cert_verify: None,
                congestion_controller: None,
                encryption: None,
                alter_id: None,
                cipher: None,
                ws_opts: None,
                up: None,
                down: None,
            },
            Proxy {
                name: "test-anytls".into(),
                proxy_type: "anytls".into(),
                server: "2.2.2.2".into(),
                port: 7000,
                uuid: None,
                password: Some("pass".into()),
                udp: Some(true),
                flow: None,
                tls: None,
                servername: None,
                sni: Some("y.com".into()),
                client_fingerprint: None,
                network: None,
                reality_opts: None,
                skip_cert_verify: Some(true),
                congestion_controller: None,
                encryption: None,
                alter_id: None,
                cipher: None,
                ws_opts: None,
                up: None,
                down: None,
            },
        ]
    }

    #[test]
    fn test_build_provider_yaml() {
        let proxies = make_test_proxies();
        let yaml = build_provider_yaml(&proxies).unwrap();
        assert!(yaml.contains("test-vless"));
        assert!(yaml.contains("test-anytls"));
        assert!(yaml.contains("vless"));
        assert!(yaml.contains("anytls"));
    }

    #[test]
    fn test_build_config_yaml() {
        let yaml = build_config_yaml("192.168.1.1");
        assert!(yaml.contains("mixed-port: 7897"));
        assert!(yaml.contains("192.168.1.1"));
        assert!(yaml.contains("proxy-providers:"));
        assert!(yaml.contains("proxy-groups:"));
        assert!(yaml.contains("dns:"));
        assert!(yaml.contains("fake-ip"));
    }

    #[test]
    fn test_generate_integration() {
        let proxies = make_test_proxies();
        let dir = tempfile::tempdir().unwrap();
        generate(&proxies, dir.path(), "192.168.1.1").unwrap();

        let config_path = dir.path().join("config.yaml");
        let provider_path = dir.path().join("providers/my_sub.yaml");
        assert!(config_path.exists(), "config.yaml should exist");
        assert!(provider_path.exists(), "providers/my_sub.yaml should exist");

        let config = std::fs::read_to_string(&config_path).unwrap();
        assert!(config.contains("mixed-port: 7897"));
    }

    #[test]
    fn test_generate_empty_proxies() {
        let proxies: Vec<Proxy> = vec![];
        let dir = tempfile::tempdir().unwrap();
        generate(&proxies, dir.path(), "192.168.1.1").unwrap();

        let provider_path = dir.path().join("providers/my_sub.yaml");
        let content = std::fs::read_to_string(provider_path).unwrap();
        assert!(content.contains("proxies: []") || content.contains("proxies:\n"));
    }
}
