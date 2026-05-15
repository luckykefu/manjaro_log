//! 代理 URI 解析模块 - 将订阅文本解析为结构化代理节点
//!
//! 支持的协议: vless, anytls, tuic, hysteria2, vmess
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! |------|------|------|------|
//! |      | raw  | &str | base64 编码的原始文本 |
//! |      | text | &str | 解码后的 URI 列表（每行一个） |
//! | 返回 |      | Result<String> | 解码后的文本 |
//! | 返回 |      | Result<Vec<Proxy>> | 解析后的代理节点列表 |
//! =============================
//! ASCII 图示处理逻辑:
//!
//! 1. decode():
//!    base64 解码 -> utf8 文本
//!    若解码失败，直接返回原文
//!
//! 2. parse_proxies():
//!    逐行解析 ->
//!      vless://    -> parse_vless()
//!      anytls://   -> parse_anytls()
//!      tuic://     -> parse_tuic()
//!      hysteria2:// -> parse_hysteria2()
//!      hy2://      -> parse_hysteria2()
//!      vmess://    -> parse_vmess()
//!    返回 Vec<Proxy>

use crate::{sinfo, swarn};
use anyhow::{Context, Result};
use serde::Serialize;
use std::collections::HashMap;

/// 代理节点结构体 - 对应 mihomo Clash YAML 格式
#[derive(Debug, Clone, Serialize)]
pub struct Proxy {
    pub name: String,
    #[serde(rename = "type")]
    pub proxy_type: String,
    pub server: String,
    pub port: u16,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub uuid: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub password: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub udp: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub flow: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tls: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub servername: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sni: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "client-fingerprint")]
    pub client_fingerprint: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub network: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "reality-opts")]
    pub reality_opts: Option<RealityOpts>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "skip-cert-verify")]
    pub skip_cert_verify: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "congestion-controller")]
    pub congestion_controller: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub encryption: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "alterId")]
    pub alter_id: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cipher: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "ws-opts")]
    pub ws_opts: Option<WsOpts>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub up: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub down: Option<String>,
}

/// VLESS Reality 配置
#[derive(Debug, Clone, Serialize)]
pub struct RealityOpts {
    #[serde(rename = "public-key")]
    pub public_key: String,
    #[serde(rename = "short-id")]
    pub short_id: String,
}

/// WebSocket 传输配置
#[derive(Debug, Clone, Serialize)]
pub struct WsOpts {
    pub path: String,
    pub headers: HashMap<String, String>,
}

/// 解码 base64 编码的订阅文本
///
/// 若解码失败则返回原文（可能是明文）。
pub fn decode(raw: &str) -> Result<String> {
    let trimmed = raw.trim();

    if let Ok(decoded) = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, trimmed)
    {
        let text =
            String::from_utf8(decoded).context("base64 decoded content is not valid UTF-8")?;
        sinfo!("[parser] decoded {} bytes of base64", trimmed.len());
        Ok(text)
    } else {
        sinfo!("[parser] not base64, using raw text");
        Ok(raw.to_string())
    }
}

/// 解析代理 URI 文本，返回代理节点列表
pub fn parse_proxies(text: &str) -> Result<Vec<Proxy>> {
    let mut proxies = Vec::new();

    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        let proxy = if let Some(rest) = line.strip_prefix("vless://") {
            parse_vless(rest)
        } else if let Some(rest) = line.strip_prefix("anytls://") {
            parse_anytls(rest)
        } else if let Some(rest) = line.strip_prefix("tuic://") {
            parse_tuic(rest)
        } else if let Some(rest) = line.strip_prefix("hysteria2://") {
            parse_hysteria2(rest)
        } else if let Some(rest) = line.strip_prefix("hy2://") {
            parse_hysteria2(rest)
        } else if let Some(rest) = line.strip_prefix("vmess://") {
            parse_vmess(rest)
        } else {
            swarn!(
                "[parser] unknown scheme, skipping: {}...",
                &line[..line.len().min(60)]
            );
            continue;
        };

        match proxy {
            Some(p) => {
                sinfo!("[parser] parsed: {} ({})", p.name, p.proxy_type);
                proxies.push(p);
            }
            None => {
                swarn!(
                    "[parser] failed to parse: {}...",
                    &line[..line.len().min(60)]
                );
            }
        }
    }

    sinfo!("[parser] total proxies parsed: {}", proxies.len());
    Ok(proxies)
}

/// 解析 VLESS URI
fn parse_vless(raw: &str) -> Option<Proxy> {
    let full = format!("vless://{raw}");
    let parsed = url::Url::parse(&full).ok()?;
    let host = parsed.host_str()?;
    let port = parsed.port().unwrap_or(443);
    let params: HashMap<String, String> = parsed.query_pairs().into_owned().collect();
    let name = urlencoding::decode(parsed.fragment().unwrap_or(""))
        .ok()
        .map(|c| c.into_owned())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| format!("vless-{host}"));

    let mut p = Proxy {
        name,
        proxy_type: "vless".into(),
        server: host.into(),
        port,
        uuid: Some(parsed.username().into()),
        password: None,
        udp: Some(true),
        flow: params.get("flow").cloned().filter(|s| !s.is_empty()),
        tls: Some(true),
        servername: params
            .get("sni")
            .or(params.get("servername"))
            .cloned()
            .or(Some(host.into())),
        sni: None,
        client_fingerprint: params.get("fp").cloned().or(Some("chrome".into())),
        network: params.get("type").cloned().or(Some("tcp".into())),
        reality_opts: None,
        skip_cert_verify: None,
        congestion_controller: None,
        encryption: params.get("encryption").cloned().or(Some("none".into())),
        alter_id: None,
        cipher: None,
        ws_opts: None,
        up: None,
        down: None,
    };

    if params
        .get("security")
        .map(|s| s == "reality")
        .unwrap_or(false)
    {
        p.reality_opts = Some(RealityOpts {
            public_key: params.get("pbk")?.clone(),
            short_id: params.get("sid").cloned().unwrap_or_default(),
        });
    }

    Some(p)
}

/// 解析 AnyTLS URI
fn parse_anytls(raw: &str) -> Option<Proxy> {
    let full = format!("anytls://{raw}");
    let parsed = url::Url::parse(&full).ok()?;
    let host = parsed.host_str()?;
    let port = parsed.port().unwrap_or(443);
    let params: HashMap<String, String> = parsed.query_pairs().into_owned().collect();
    let name = urlencoding::decode(parsed.fragment().unwrap_or(""))
        .ok()
        .map(|c| c.into_owned())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| format!("anytls-{host}"));

    Some(Proxy {
        name,
        proxy_type: "anytls".into(),
        server: host.into(),
        port,
        uuid: None,
        password: Some(parsed.username().into()),
        udp: Some(true),
        flow: None,
        tls: None,
        servername: None,
        sni: params.get("sni").cloned().or(Some(host.into())),
        client_fingerprint: None,
        network: None,
        reality_opts: None,
        skip_cert_verify: params.get("insecure").map(|v| v == "1"),
        congestion_controller: None,
        encryption: None,
        alter_id: None,
        cipher: None,
        ws_opts: None,
        up: None,
        down: None,
    })
}

/// 解析 TUIC URI
fn parse_tuic(raw: &str) -> Option<Proxy> {
    let full = format!("tuic://{raw}");
    let parsed = url::Url::parse(&full).ok()?;
    let host = parsed.host_str()?;
    let port = parsed.port().unwrap_or(443);
    let params: HashMap<String, String> = parsed.query_pairs().into_owned().collect();
    let name = urlencoding::decode(parsed.fragment().unwrap_or(""))
        .ok()
        .map(|c| c.into_owned())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| format!("tuic-{host}"));

    Some(Proxy {
        name,
        proxy_type: "tuic".into(),
        server: host.into(),
        port,
        uuid: Some(parsed.username().into()),
        password: params
            .get("password")
            .cloned()
            .or(Some(parsed.username().into())),
        udp: Some(true),
        flow: None,
        tls: None,
        servername: None,
        sni: params.get("sni").cloned().or(Some(host.into())),
        client_fingerprint: None,
        network: None,
        reality_opts: None,
        skip_cert_verify: Some(true),
        congestion_controller: params
            .get("congestion_controller")
            .cloned()
            .or(Some("bbr".into())),
        encryption: None,
        alter_id: None,
        cipher: None,
        ws_opts: None,
        up: None,
        down: None,
    })
}

/// 解析 Hysteria2 URI
fn parse_hysteria2(raw: &str) -> Option<Proxy> {
    let full = format!("hysteria2://{raw}");
    let parsed = url::Url::parse(&full).ok()?;
    let host = parsed.host_str()?;
    let port = parsed.port().unwrap_or(443);
    let params: HashMap<String, String> = parsed.query_pairs().into_owned().collect();
    let name = urlencoding::decode(parsed.fragment().unwrap_or(""))
        .ok()
        .map(|c| c.into_owned())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| format!("hy2-{host}"));

    Some(Proxy {
        name,
        proxy_type: "hysteria2".into(),
        server: host.into(),
        port,
        uuid: None,
        password: Some(parsed.username().into()),
        udp: Some(true),
        flow: None,
        tls: None,
        servername: None,
        sni: params.get("sni").cloned().or(Some(host.into())),
        client_fingerprint: None,
        network: None,
        reality_opts: None,
        skip_cert_verify: params.get("insecure").map(|v| v == "1"),
        congestion_controller: None,
        encryption: None,
        alter_id: None,
        cipher: None,
        ws_opts: None,
        up: params.get("up").cloned(),
        down: params.get("down").cloned(),
    })
}

/// 解析 VMess URI (base64 JSON 格式)
fn parse_vmess(raw: &str) -> Option<Proxy> {
    let decoded =
        base64::Engine::decode(&base64::engine::general_purpose::STANDARD, raw.trim()).ok()?;
    let v: serde_json::Value = serde_json::from_slice(&decoded).ok()?;
    let name = v
        .get("ps")
        .and_then(|s| s.as_str())
        .filter(|s| !s.is_empty())
        .unwrap_or("vmess")
        .to_string();
    let host = v.get("add").and_then(|s| s.as_str()).unwrap_or("");
    let port: u16 = v.get("port").and_then(|s| s.as_u64()).unwrap_or(443) as u16;

    let mut p = Proxy {
        name,
        proxy_type: "vmess".into(),
        server: host.into(),
        port,
        uuid: v.get("id").and_then(|s| s.as_str()).map(|s| s.into()),
        password: None,
        udp: Some(true),
        flow: None,
        tls: None,
        servername: None,
        sni: None,
        client_fingerprint: None,
        network: None,
        reality_opts: None,
        skip_cert_verify: None,
        congestion_controller: None,
        encryption: None,
        alter_id: Some(
            v.get("aid")
                .and_then(|s| s.as_u64())
                .map(|s| s as u16)
                .unwrap_or(0),
        ),
        cipher: v
            .get("scy")
            .and_then(|s| s.as_str())
            .map(|s| s.into())
            .or(Some("auto".into())),
        ws_opts: None,
        up: None,
        down: None,
    };

    if v.get("net").and_then(|s| s.as_str()) == Some("ws") {
        p.network = Some("ws".into());
        let path = v.get("path").and_then(|s| s.as_str()).unwrap_or("/");
        let host_h = v.get("host").and_then(|s| s.as_str()).unwrap_or(host);
        let mut headers = HashMap::new();
        headers.insert("Host".into(), host_h.into());
        p.ws_opts = Some(WsOpts {
            path: path.into(),
            headers,
        });
    }

    Some(p)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_decode_plain_text() {
        let text = "vless://abc@example.com:443";
        let result = decode(text).unwrap();
        assert_eq!(result, text);
    }

    #[test]
    fn test_decode_base64() {
        let encoded = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, b"hello");
        let result = decode(&encoded).unwrap();
        assert_eq!(result, "hello");
    }

    #[test]
    fn test_parse_vless_reality() {
        let uri = "814c8f12-8eaa-4c85-ad22-6778281c5d4c@185.229.222.216:443?security=reality&pbk=testkey&sid=123&sni=example.com&fp=chrome&type=tcp#test-node";
        let p = parse_vless(uri).unwrap();
        assert_eq!(p.proxy_type, "vless");
        assert_eq!(p.server, "185.229.222.216");
        assert_eq!(p.port, 443);
        assert!(p.reality_opts.is_some());
        assert_eq!(p.reality_opts.as_ref().unwrap().public_key, "testkey");
        assert_eq!(p.reality_opts.as_ref().unwrap().short_id, "123");
        assert_eq!(p.servername.as_deref(), Some("example.com"));
        assert_eq!(p.client_fingerprint.as_deref(), Some("chrome"));
    }

    #[test]
    fn test_parse_anytls() {
        let uri = "password@server.example.com:7000?sni=www.microsoft.com&insecure=1#test-anytls";
        let p = parse_anytls(uri).unwrap();
        assert_eq!(p.proxy_type, "anytls");
        assert_eq!(p.server, "server.example.com");
        assert_eq!(p.port, 7000);
        assert_eq!(p.password.as_deref(), Some("password"));
        assert_eq!(p.sni.as_deref(), Some("www.microsoft.com"));
    }

    #[test]
    fn test_parse_tuic() {
        let uri =
            "uuid@tuic.example.com:56000?password=pass123&congestion_controller=bbr#test-tuic";
        let p = parse_tuic(uri).unwrap();
        assert_eq!(p.proxy_type, "tuic");
        assert_eq!(p.uuid.as_deref(), Some("uuid"));
        assert_eq!(p.congestion_controller.as_deref(), Some("bbr"));
    }

    #[test]
    fn test_parse_hysteria2() {
        let uri = "pass123@hy2.example.com:45114?sni=hy2.example.com&up=100&down=200#test-hy2";
        let p = parse_hysteria2(uri).unwrap();
        assert_eq!(p.proxy_type, "hysteria2");
        assert_eq!(p.password.as_deref(), Some("pass123"));
        assert_eq!(p.up.as_deref(), Some("100"));
        assert_eq!(p.down.as_deref(), Some("200"));
    }

    #[test]
    fn test_parse_vmess() {
        let vmess = r#"{"ps":"test-vmess","add":"vmess.example.com","port":8080,"id":"uuid-123","aid":0,"scy":"auto","net":"ws","path":"/","host":"vmess.example.com"}"#;
        let encoded =
            base64::Engine::encode(&base64::engine::general_purpose::STANDARD, vmess.as_bytes());
        let p = parse_vmess(&encoded).unwrap();
        assert_eq!(p.proxy_type, "vmess");
        assert_eq!(p.server, "vmess.example.com");
        assert_eq!(p.port, 8080);
        assert_eq!(p.alter_id, Some(0));
        assert!(p.ws_opts.is_some());
    }

    #[test]
    fn test_parse_vmess_no_aid() {
        let vmess =
            r#"{"ps":"no-aid","add":"vmess2.example.com","port":80,"id":"uuid","scy":"auto"}"#;
        let encoded =
            base64::Engine::encode(&base64::engine::general_purpose::STANDARD, vmess.as_bytes());
        let p = parse_vmess(&encoded).unwrap();
        assert_eq!(p.alter_id, Some(0));
        assert!(p.ws_opts.is_none());
    }

    #[test]
    fn test_parse_proxies_mixed() {
        let text = "\
vless://uuid@1.1.1.1:443?security=reality&pbk=key&sid=abc&sni=x.com&fp=chrome#node1
anytls://pass@2.2.2.2:443?sni=y.com&insecure=1#node2
invalid_line_here
";
        let proxies = parse_proxies(text).unwrap();
        assert_eq!(proxies.len(), 2);
        assert_eq!(proxies[0].proxy_type, "vless");
        assert_eq!(proxies[1].proxy_type, "anytls");
    }

    #[test]
    fn test_empty_input() {
        let proxies = parse_proxies("").unwrap();
        assert!(proxies.is_empty());
    }

    #[test]
    fn test_vmess_ws_opts() {
        let vmess = r#"{"ps":"ws-node","add":"ws.example.com","port":443,"id":"uuid","aid":0,"scy":"auto","net":"ws","path":"/ws","host":"ws.example.com"}"#;
        let encoded =
            base64::Engine::encode(&base64::engine::general_purpose::STANDARD, vmess.as_bytes());
        let p = parse_vmess(&encoded).unwrap();
        assert_eq!(p.network.as_deref(), Some("ws"));
        let ws = p.ws_opts.unwrap();
        assert_eq!(ws.path, "/ws");
        assert_eq!(ws.headers.get("Host").unwrap(), "ws.example.com");
    }
}
