//! 订阅下载模块 - 从远程 URL 获取代理订阅内容
//!
//! 支持直连和通过 HTTP 代理两种方式下载。
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! |------|------|------|------|
//! |      | url  | &str | 订阅链接 URL |
//! |      | proxy | Option<&str> | HTTP 代理地址，如 "http://127.0.0.1:7897" |
//! | 返回 |      | Result<String> | 原始订阅内容（base64 编码文本） |
//! =============================
//! ASCII 图示处理逻辑:
//!
//! 1. 创建 HTTP 客户端 (30s 超时) -> reqwest::Client
//! 2. 若 proxy 有值，设置代理 -> client.proxy()
//! 3. GET 请求订阅链接 -> client.get(url).send()?
//! 4. 读取响应体 -> resp.text()
//! 5. 返回原始文本 -> Ok(text)

use crate::sinfo;
use anyhow::{Context, Result};

/// 通过 HTTP(S) 下载订阅内容
///
/// ## 示例
/// ```ignore
/// let raw = download("https://example.com/sub", None)?;
/// let raw = download("https://example.com/sub", Some("http://127.0.0.1:7897"))?;
/// ```
pub fn download(url: &str, proxy: Option<&str>) -> Result<String> {
    // 步骤 1: 构建 HTTP 客户端
    let mut client_builder =
        reqwest::blocking::Client::builder().timeout(std::time::Duration::from_secs(30));

    // 步骤 2: 若指定了代理则添加
    if let Some(proxy_url) = proxy {
        let p =
            reqwest::Proxy::http(proxy_url).context(format!("invalid proxy url: {proxy_url}"))?;
        client_builder = client_builder.proxy(p);
        sinfo!("[subscribe] using proxy: {proxy_url}");
    }

    let client = client_builder
        .build()
        .context("failed to build HTTP client")?;

    // 步骤 3: 发送 GET 请求
    sinfo!("[subscribe] downloading from: {url}");
    let resp = client
        .get(url)
        .send()
        .context(format!("failed to fetch subscription: {url}"))?;

    if !resp.status().is_success() {
        anyhow::bail!("HTTP {}: {}", resp.status(), url);
    }

    // 步骤 4: 读取响应体
    let text = resp.text().context("failed to read response body")?;

    sinfo!("[subscribe] downloaded {} bytes", text.len());
    Ok(text)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// 测试下载函数能正确处理无效 URL
    #[test]
    fn test_download_invalid_url() {
        let result = download("http://127.0.0.1:1/invalid", None);
        assert!(result.is_err());
    }
}
