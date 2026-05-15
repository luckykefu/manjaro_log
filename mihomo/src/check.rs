//! 连通性测试模块 - 启动 mihomo 后验证代理是否正常工作
//!
//! ============================
//! 入参说明
//! | 入参 | 参数 | 类型 | 说明 |
//! |------|------|------|------|
//! |      | controller_port | u16 | 外部控制端口 (默认 9097) |
//! |      | proxy_port | u16 | 混合代理端口 (默认 7897) |
//! |      | timeout_secs | u64 | 等待 mihomo 启动的秒数 |
//! | 返回 | | Result<()> | 成功或错误 |
//! =============================
//! ASCII 图示处理逻辑:
//!
//! 1. 等待 mihomo 启动 -> sleep(3s)
//! 2. 查询外部控制器 API -> GET /proxies/proxy
//! 3. 获取当前选中节点 -> "now" 字段
//! 4. 通过代理访问 http://www.gstatic.com/generate_204
//! 5. 打印结果（节点名 + 延迟）

use crate::{sinfo, swarn};
use anyhow::{Context, Result};
use serde::Deserialize;
use std::time::{Duration, Instant};

/// mihomo 外部控制器 API 的 proxy 组响应
#[derive(Debug, Deserialize)]
struct ProxyGroup {
    #[allow(dead_code)]
    name: String,
    #[allow(dead_code)]
    r#type: String,
    now: String,
}

/// 等待 mihomo 启动并执行连通性检查
///
/// ## 参数
/// - `controller_port`: 外部控制器端口
/// - `proxy_port`: 混合代理端口
/// - `output_dir`: 用于提示用户检查日志
pub fn check_connectivity(controller_port: u16, proxy_port: u16, output_dir: &str) {
    sinfo!("[check] waiting 3s for mihomo to start...");
    std::thread::sleep(Duration::from_secs(3));

    // 步骤 1: 查询当前选中的节点
    let node = get_selected_node(controller_port);

    // 步骤 2: 通过代理测试连通性
    let latency = test_proxy(proxy_port);

    // 步骤 3: 汇总显示
    match (&node, &latency) {
        (Ok(node), Ok(latency)) => {
            sinfo!(
                "[check] ✅ proxy working | node: {} | latency: {}ms",
                node,
                latency
            );
        }
        (Err(_), Ok(latency)) => {
            sinfo!("[check] ✅ proxy reachable | latency: {}ms", latency);
        }
        (_, Err(_)) => {
            swarn!("[check] mihomo not ready, check logs: {}", output_dir);
            swarn!("[check]   tail -f /tmp/mihomo.log");
        }
    }
}

/// 查询 mihomo 外部控制器，获取 proxy 组当前选中的节点
fn get_selected_node(port: u16) -> Result<String> {
    let url = format!("http://127.0.0.1:{}/proxies/proxy", port);
    let client = reqwest::blocking::Client::builder()
        .timeout(Duration::from_secs(3))
        .build()
        .context("failed to build HTTP client")?;

    let resp = client
        .get(&url)
        .send()
        .context(format!("failed to query mihomo controller at {url}"))?;

    if !resp.status().is_success() {
        anyhow::bail!("controller returned HTTP {}", resp.status());
    }

    let body = resp.text().context("failed to read controller response")?;
    let group: ProxyGroup =
        serde_json::from_str(&body).context("failed to parse controller response")?;

    Ok(group.now)
}

/// 通过 mihomo 代理访问测试 URL，测量延迟
fn test_proxy(port: u16) -> Result<u64> {
    let proxy_url = format!("http://127.0.0.1:{}", port);
    let test_url = "http://www.gstatic.com/generate_204";

    let proxy =
        reqwest::Proxy::http(&proxy_url).context(format!("invalid proxy url: {proxy_url}"))?;

    let client = reqwest::blocking::Client::builder()
        .proxy(proxy)
        .timeout(Duration::from_secs(10))
        .build()
        .context("failed to build HTTP client")?;

    let start = Instant::now();
    let resp = client
        .get(test_url)
        .send()
        .context(format!("failed to reach {test_url} through proxy"))?;

    if !resp.status().is_success() {
        anyhow::bail!("test URL returned HTTP {}", resp.status());
    }

    let elapsed = start.elapsed().as_millis() as u64;
    Ok(elapsed)
}
