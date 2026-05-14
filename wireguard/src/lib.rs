//! WireGuard 一键部署
//!
//! 自动化部署 WireGuard 服务端与客户端，支持 Manjaro/Arch Linux 环境
//!
//! ============================
//! 入参说明
//! | 类型 | 名称 | 说明 |
//! |------|------|------|
//! | struct | WireGuardConfig | 部署配置: 服务端 IP、端口、隧道 IP 等 |
//! | fn | deploy_wireguard | 10 步部署主流程 |
//! | fn | switch_wireguard | 用已有配置快速连接 |
//! | const | DEFAULT_WG_* | 默认配置常量 |
//! | 返回 | | Result<()> |
//! =============================
//! ASCII图示处理逻辑:
//!
//! deploy_wireguard(cfg):
//!  1 -> client::push_key            SSH 公钥推送
//!  2 -> client::ensure_tools        本地依赖检查
//!  3 -> server::run_init            服务端初始化脚本 (SCP)
//!        ├─ detect_firewall + install + open_firewall
//!        └─ gen_keys + get_iface → 返回 (fw, priv, pub, iface)
//!  4 -> client::gen_keys            客户端密钥对
//!  5 -> client::write_config        客户端 .conf 写入
//!  6 -> server::run_apply           服务端配置脚本 (SCP)
//!        ├─ write_config + enable_ip_forwarding
//!        └─ start_wg
//!  7 -> client::save_server_pubkey  保存服务端公钥
//!  8 -> client::start_wg            客户端 wg-quick 启动
//!  9 -> ping 测试                   隧道连通性验证
//! 10 -> client::key_exchange        双向 SSH 密钥交换
//! 返回 -> ()
//!
//! switch_wireguard(ip):
//!   |- ip -> wg_name ('.' -> '-')
//!   +- client::switch_wg            用已有配置连接
//! 返回 -> ()

pub mod client;
pub mod cmd;
pub mod server;
pub mod slog;

use anyhow::Result;

pub const DEFAULT_WG_IP: &str = "64.176.225.208";
pub const DEFAULT_WG_PORT: u16 = 51820;
pub const DEFAULT_WG_DIR: &str = "/etc/wireguard";
pub const DEFAULT_WG_SERVER_IP: &str = "10.0.0.1";
pub const DEFAULT_WG_CLIENT_IP: &str = "10.0.0.2";
pub const DEFAULT_WG_SUBNET: &str = "24";

pub struct WireGuardConfig {
    pub server_ip: String,
    pub port: u16,
    pub dir: String,
    pub tunnel_server_ip: String,
    pub tunnel_client_ip: String,
    pub subnet: String,
}

impl Default for WireGuardConfig {
    fn default() -> Self {
        Self {
            server_ip: DEFAULT_WG_IP.to_string(),
            port: DEFAULT_WG_PORT,
            dir: DEFAULT_WG_DIR.to_string(),
            tunnel_server_ip: DEFAULT_WG_SERVER_IP.to_string(),
            tunnel_client_ip: DEFAULT_WG_CLIENT_IP.to_string(),
            subnet: DEFAULT_WG_SUBNET.to_string(),
        }
    }
}

pub fn deploy_wireguard(cfg: &WireGuardConfig) -> Result<()> {
    let total: u8 = 10;
    let ip = &cfg.server_ip;
    let wg_dir = &cfg.dir;
    let wg_name = ip.replace('.', "-");
    sdebug!(
        "deploy_wireguard ip={ip} port={} wg_name={wg_name}",
        cfg.port
    );

    slog::step(1, total, "Push SSH public key");
    client::push_key(ip)?;

    slog::step(2, total, "Check client dependencies");
    client::ensure_tools()?;

    slog::step(
        3,
        total,
        "Server init script (firewall + install + keys + iface)",
    );
    let info = server::run_init(ip, cfg.port, wg_dir)?;

    slog::step(4, total, "Generate client key pair");
    let local_pub = client::gen_keys(wg_dir)?;

    slog::step(5, total, "Write client config");
    client::write_config(wg_dir, &wg_name, &info.server_pub, cfg)?;

    slog::step(
        6,
        total,
        "Server apply script (config + forwarding + start)",
    );
    server::run_apply(
        ip,
        wg_dir,
        &wg_name,
        &info.iface,
        &local_pub,
        &info.server_priv,
        cfg,
    )?;

    slog::step(7, total, "Save server public key locally");
    client::save_server_pubkey(wg_dir, &info.server_pub)?;

    slog::step(8, total, "Start wg-quick locally");
    client::start_wg(&wg_name)?;

    slog::step(9, total, "Ping test");
    match cmd::run("ping", &["-c", "3", "-W", "3", &cfg.tunnel_server_ip]) {
        Ok(_) => slog::ok("Ping OK!"),
        Err(e) => {
            let client_iface = cmd::bash_exec(&format!(
                "ip addr show {wg_name} 2>/dev/null || echo 'interface not found'"
            ))
            .unwrap_or_default();
            let client_route =
                cmd::bash_exec("ip route get 10.0.0.1 2>/dev/null || echo 'no route'")
                    .unwrap_or_default();
            let client_ss =
                cmd::bash_exec("sudo ss -lnup 2>/dev/null || echo 'ss failed'").unwrap_or_default();
            let client_nc = cmd::bash_exec(&format!(
                "nc -zv -u -w 3 {ip} {} 2>&1 || echo 'port unreachable'",
                cfg.port
            ))
            .unwrap_or_default();
            let server_wg = cmd::ssh(
                &format!("root@{ip}"),
                "sudo wg show 2>&1 || echo 'wg show failed'",
            )
            .unwrap_or_default();
            serror!("ping failed: {e}");
            serror!(
                "--- local interface ---\n{}--- route ---\n{}--- nc ---\n{}--- ss ---\n{}--- remote wg ---\n{}",
                client_iface,
                client_route,
                client_nc,
                client_ss,
                server_wg
            );
            swarn!("Check:");
            swarn!("  1) Server firewall UDP {} open", cfg.port);
            swarn!("  2) iptables PostUp rules active");
            anyhow::bail!("ping failed");
        }
    }

    slog::step(10, total, "SSH key exchange");
    client::key_exchange(ip)?;

    slog::ok("WireGuard deployed!");
    slog::info(&format!("Server pubkey: {}", info.server_pub.trim()));
    slog::info(&format!("Client IP: {}", cfg.tunnel_client_ip));
    slog::info(&format!("SSH tunnel: ssh lkf@{}", cfg.tunnel_server_ip));
    sdebug!("deploy_wireguard done");
    Ok(())
}

pub fn switch_wireguard(ip: &str) -> Result<()> {
    let wg_name = ip.replace('.', "-");
    sdebug!("switch_wireguard ip={ip} wg_name={wg_name}");
    slog::step(1, 2, "Clean old interfaces");
    client::switch_wg(&wg_name, DEFAULT_WG_DIR)?;
    slog::step(2, 2, "Ping test");
    match cmd::run("ping", &["-c", "3", "-W", "3", DEFAULT_WG_SERVER_IP]) {
        Ok(_) => slog::ok("Ping OK!"),
        Err(e) => {
            let status = cmd::sudo(&["wg", "show"]).unwrap_or_default();
            serror!("ping failed: {e}");
            serror!("--- wg status ---\n{status}");
            anyhow::bail!("ping failed");
        }
    }
    slog::ok(&format!("WireGuard {wg_name} connected"));
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_wg_ip() {
        assert_eq!(DEFAULT_WG_IP, "64.176.225.208");
    }

    #[test]
    fn test_default_wg_port() {
        assert_eq!(DEFAULT_WG_PORT, 51820u16);
    }

    #[test]
    fn test_default_wg_dir() {
        assert_eq!(DEFAULT_WG_DIR, "/etc/wireguard");
    }

    #[test]
    fn test_default_wg_server_ip() {
        assert_eq!(DEFAULT_WG_SERVER_IP, "10.0.0.1");
    }

    #[test]
    fn test_default_wg_client_ip() {
        assert_eq!(DEFAULT_WG_CLIENT_IP, "10.0.0.2");
    }

    #[test]
    fn test_default_wg_subnet() {
        assert_eq!(DEFAULT_WG_SUBNET, "24");
    }

    #[test]
    fn test_wireguard_config_default() {
        let cfg = WireGuardConfig::default();
        assert_eq!(cfg.server_ip, DEFAULT_WG_IP);
        assert_eq!(cfg.port, DEFAULT_WG_PORT);
        assert_eq!(cfg.tunnel_server_ip, DEFAULT_WG_SERVER_IP);
        assert_eq!(cfg.tunnel_client_ip, DEFAULT_WG_CLIENT_IP);
        assert_eq!(cfg.subnet, DEFAULT_WG_SUBNET);
    }
}
