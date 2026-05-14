//! WireGuard 一键部署工具 — CLI 入口
//!
//! 解析命令行参数和环境变量，构建 WireGuardConfig，调用 deploy_wireguard
//!
//! ============================
//! 入参说明
//! | 参数 | 环境变量 | 默认值 | 说明 |
//! |------|---------|--------|------|
//! | --server-ip | WG_SERVER_IP | 64.176.225.208 | 服务端公网 IP |
//! | --port | WG_PORT | 51820 | WireGuard UDP 端口 |
//! | --dir | WG_DIR | /etc/wireguard | 配置目录 |
//! | --tunnel-srv | WG_TUNNEL_SERVER | 10.0.0.1 | 隧道服务端 IP |
//! | --tunnel-cli | WG_TUNNEL_CLIENT | 10.0.0.2 | 隧道客户端 IP |
//! | --subnet | WG_SUBNET | 24 | 子网掩码位数 |
//! | --switch | IP | — | 用已有配置连接远程（跳过部署）|
//! | 返回 | | | 部署/连接结果 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! --switch 模式:
//!   |- 解析 --switch IP
//!   +- lib::switch_wireguard(ip)
//! 正常模式:
//!   1 解析 CLI 参数 + 环境变量覆写默认配置
//!   2 构建 WireGuardConfig
//!   3 调用 lib::deploy_wireguard()
//! 返回 -> 部署成功/失败

use anyhow::Result;
use std::env;
use wireguard::{WireGuardConfig, deploy_wireguard, switch_wireguard};

fn parse_arg_or_env(key: &str, default: &str) -> String {
    env::var(format!("WG_{}", key.replace('-', "_").to_uppercase()))
        .unwrap_or_else(|_| default.to_string())
}

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    if let Some(pos) = args.iter().position(|a| a == "--switch") {
        if let Some(ip) = args.get(pos + 1) {
            return switch_wireguard(ip);
        }
        anyhow::bail!("--switch requires an IP argument");
    }

    let mut cfg = WireGuardConfig {
        server_ip: parse_arg_or_env("server-ip", wireguard::DEFAULT_WG_IP),
        port: parse_arg_or_env("port", &wireguard::DEFAULT_WG_PORT.to_string())
            .parse()
            .unwrap_or(wireguard::DEFAULT_WG_PORT),
        dir: parse_arg_or_env("dir", wireguard::DEFAULT_WG_DIR),
        tunnel_server_ip: parse_arg_or_env("tunnel-srv", wireguard::DEFAULT_WG_SERVER_IP),
        tunnel_client_ip: parse_arg_or_env("tunnel-cli", wireguard::DEFAULT_WG_CLIENT_IP),
        subnet: parse_arg_or_env("subnet", wireguard::DEFAULT_WG_SUBNET),
    };

    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--server-ip" => {
                i += 1;
                cfg.server_ip = args[i].clone();
            }
            "--port" => {
                i += 1;
                cfg.port = args[i].parse()?;
            }
            "--dir" => {
                i += 1;
                cfg.dir = args[i].clone();
            }
            "--tunnel-srv" => {
                i += 1;
                cfg.tunnel_server_ip = args[i].clone();
            }
            "--tunnel-cli" => {
                i += 1;
                cfg.tunnel_client_ip = args[i].clone();
            }
            "--subnet" => {
                i += 1;
                cfg.subnet = args[i].clone();
            }
            _ => {}
        }
        i += 1;
    }

    deploy_wireguard(&cfg)
}
