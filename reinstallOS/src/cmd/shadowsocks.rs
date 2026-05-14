use std::path::PathBuf;
use std::time::Duration;

use crate::run_cmd::{self, RunConfig};
use crate::{sdebug, serror, sinfo, swarn};

pub const DEFAULT_SS_PORT: u16 = 1080;
pub const DEFAULT_SS_SVR_PORT: u16 = 8388;

pub struct ShadowsocksConfig {
    pub ip: String,
    pub local_port: u16,
    pub server_port: u16,
}

impl ShadowsocksConfig {
    pub fn new(ip: &str) -> Self {
        Self {
            ip: ip.to_string(),
            local_port: DEFAULT_SS_PORT,
            server_port: DEFAULT_SS_SVR_PORT,
        }
    }
}

fn home_shadowsocks() -> PathBuf {
    let home = std::env::var("HOME")
        .or_else(|_| std::env::var("SUDO_HOME"))
        .unwrap_or_else(|_| "/root".to_string());
    PathBuf::from(home).join(".config/shadowsocks")
}

fn bash_exec(script: &str) -> anyhow::Result<String> {
    let out = run_cmd::capture_output(&RunConfig::new("bash", &["-c", script]))?;
    Ok(out)
}

fn ssh_exec(host: &str, cmd: &str) -> anyhow::Result<String> {
    run_cmd::capture_output(&RunConfig::new(
        "ssh",
        &[
            "-o",
            "StrictHostKeyChecking=accept-new",
            "-o",
            "ConnectTimeout=10",
            host,
            cmd,
        ],
    ))
}

fn sudo_exec(args: &[&str]) -> anyhow::Result<()> {
    let mut full = Vec::with_capacity(args.len());
    full.extend_from_slice(args);
    run_cmd::execute_and_wait(&RunConfig::new("sudo", &full))
}

fn ensure_cmd_or_install(cmd: &str, pkg: &str) -> anyhow::Result<()> {
    if bash_exec(&format!("command -v {cmd}")).is_ok() {
        return Ok(());
    }
    sinfo!("{cmd} not found, installing {pkg}");
    sudo_exec(&["pacman", "-S", "--noconfirm", "--needed", pkg])
}

fn step(current: u8, total: u8, msg: &str) {
    sinfo!("[{}/{}] {}", current, total, msg);
}

pub fn deploy_shadowsocks_with(cfg: &ShadowsocksConfig) -> anyhow::Result<()> {
    let total: u8 = 9;
    let ip = &cfg.ip;
    let port = cfg.local_port;
    let svr_port = cfg.server_port;

    step(1, total, "Push SSH public key");
    run_cmd::execute_and_wait(&RunConfig::new("ssh-keygen", &["-R", ip])).ok();
    bash_exec(&format!("ssh-copy-id -i ~/.ssh/id_ed25519.pub root@{ip}"))
        .map_err(|e| anyhow::anyhow!("ssh-copy-id failed: {e}"))?;

    step(2, total, "Detect server firewall");
    let fw = ssh_exec(
        &format!("root@{ip}"),
        "command -v firewall-cmd &>/dev/null && echo firewalld || (command -v ufw &>/dev/null && echo ufw || (command -v nft &>/dev/null && echo nftables || echo iptables))",
    )?;
    sinfo!("server firewall: {fw}");

    step(3, total, "Install & configure server");
    let password = ssh_exec(&format!("root@{ip}"), "openssl rand -base64 32")?;
    let svr_config = serde_json::json!({
        "server": "0.0.0.0",
        "server_port": svr_port,
        "password": password.trim(),
        "method": "2022-blake3-aes-256-gcm",
        "timeout": 300,
        "fast_open": true,
        "mode": "tcp_and_udp",
    });
    let svr_json = serde_json::to_string_pretty(&svr_config)?;
    ssh_exec(
        &format!("root@{ip}"),
        &format!(
            "sudo mkdir -p /etc/shadowsocks-rust && sudo tee /etc/shadowsocks-rust/{ip}.json > /dev/null << 'JSONEOF'\n{svr_json}\nJSONEOF"
        ),
    )?;
    ssh_exec(
        &format!("root@{ip}"),
        "sudo pacman -S --noconfirm --needed shadowsocks-rust > /dev/null 2>&1",
    )?;
    ssh_exec(
        &format!("root@{ip}"),
        &format!(
            "sudo systemctl enable \"shadowsocks-rust-server@{ip}\" && sudo systemctl restart \"shadowsocks-rust-server@{ip}\""
        ),
    )?;

    match fw.trim() {
        "firewalld" => {
            ssh_exec(
                &format!("root@{ip}"),
                &format!(
                    "firewall-cmd --add-port={svr_port}/tcp --permanent && firewall-cmd --add-port={svr_port}/udp --permanent && firewall-cmd --reload"
                ),
            )?;
        }
        "ufw" => {
            ssh_exec(
                &format!("root@{ip}"),
                &format!("ufw allow {svr_port}/tcp && ufw allow {svr_port}/udp"),
            )?;
        }
        "nftables" => swarn!("nftables, open port manually"),
        _ => {
            ssh_exec(
                &format!("root@{ip}"),
                &format!(
                    "iptables -A INPUT -p tcp --dport {svr_port} -j ACCEPT && iptables -A INPUT -p udp --dport {svr_port} -j ACCEPT"
                ),
            )?;
        }
    }
    sinfo!("firewall port {svr_port} opened");

    step(4, total, "Install local deps");
    sudo_exec(&[
        "pacman",
        "-S",
        "--needed",
        "--noconfirm",
        "shadowsocks-rust",
        "openssh",
    ])?;

    step(5, total, "Pull remote config");
    let cfg_dir = home_shadowsocks();
    std::fs::create_dir_all(&cfg_dir)?;
    let local_cfg = cfg_dir.join(format!("{ip}.json"));
    let tmp = std::env::temp_dir().join(format!("ss_deploy_{}", std::process::id()));
    run_cmd::execute_and_wait(&RunConfig::new(
        "scp",
        &[
            "-o",
            "StrictHostKeyChecking=accept-new",
            "-o",
            "ConnectTimeout=10",
            &format!("root@{ip}:/etc/shadowsocks-rust/{ip}.json"),
            &tmp.to_string_lossy(),
        ],
    ))?;
    let raw = std::fs::read_to_string(&tmp)?;
    std::fs::remove_file(&tmp).ok();
    let mut v: serde_json::Value = serde_json::from_str(&raw)?;
    if let Some(obj) = v.as_object_mut() {
        obj.remove("mode");
    }
    v["server"] = serde_json::Value::String(ip.to_string());
    v["local_address"] = serde_json::Value::String("0.0.0.0".to_string());
    v["local_port"] = serde_json::json!(port);
    let local_json = serde_json::to_string_pretty(&v)?;
    std::fs::write(&local_cfg, &local_json)?;
    sinfo!("local config written to {}", local_cfg.display());

    step(6, total, "Clean old sslocal");
    bash_exec(&format!(
        "sudo pkill sslocal 2>/dev/null; sudo fuser -k {port}/tcp 2>/dev/null; true"
    ))
    .ok();
    std::thread::sleep(Duration::from_secs(1));

    step(7, total, &format!("Start sslocal (port {port})"));
    let log_file = cfg_dir.join("ss_deploy.log");
    let mut ready = false;
    for attempt in 1..=3 {
        bash_exec(&format!(
            "sudo pkill sslocal 2>/dev/null; sudo fuser -k {port}/tcp 2>/dev/null; true"
        ))
        .ok();
        std::thread::sleep(Duration::from_secs(1));
        let result = bash_exec(&format!(
            "nohup sslocal -c {} > {} 2>&1 & SSPID=$!; sleep 1; if kill -0 $SSPID 2>/dev/null && ss -tlnp 2>/dev/null | grep -q \":{port} .*pid=$SSPID\"; then echo \"OK $SSPID\"; else echo \"FAIL\"; fi",
            local_cfg.display(), log_file.display()
        )).unwrap_or_default();
        if result.trim().starts_with("OK") {
            ready = true;
            let pid = result.trim().trim_start_matches("OK ");
            sinfo!("sslocal PID {pid} listening (attempt {attempt})");
            break;
        }
        swarn!("sslocal start failed (attempt {attempt})");
    }
    if !ready {
        let diag = bash_exec("pgrep -x sslocal 2>/dev/null && echo 'alive' || echo 'dead'")
            .unwrap_or_default();
        let log_tail = bash_exec(&format!(
            "tail -5 {} 2>/dev/null || echo 'no log'",
            log_file.display()
        ))
        .unwrap_or_default();
        serror!("sslocal not listening. process: {diag}, log: {log_tail}");
        anyhow::bail!("sslocal port {port} not ready");
    }

    step(8, total, "Connectivity test");
    let mut connected = false;
    let urls = ["http://www.google.com", "http://www.baidu.com"];
    for attempt in 1..=3 {
        let mut code = String::new();
        for url in &urls {
            code = bash_exec(&format!(
                "code=$(curl -x socks5://127.0.0.1:{port} -s -o /dev/null -w '%{{http_code}}' --connect-timeout 10 {url} 2>/dev/null) || code=000; echo \"$code\""
            )).unwrap_or_default();
            if code.trim() == "200" {
                break;
            }
        }
        if code.trim() == "200" {
            connected = true;
            break;
        }
        swarn!(
            "connectivity failed (attempt {attempt}): HTTP {}",
            code.trim()
        );
        std::thread::sleep(Duration::from_secs(2));
    }
    if !connected {
        let server_status = ssh_exec(
            &format!("root@{ip}"),
            &format!(
                "systemctl is-active shadowsocks-rust-server@{ip} 2>/dev/null || echo inactive"
            ),
        )
        .unwrap_or_default();
        let sslocal_log = bash_exec(&format!(
            "tail -10 {} 2>/dev/null || echo 'no log'",
            log_file.display()
        ))
        .unwrap_or_default();
        serror!(
            "connectivity failed. server={}, log: {}",
            server_status.trim(),
            sslocal_log.trim()
        );
        anyhow::bail!("proxy connectivity failed");
    }

    step(9, total, "Done");
    sinfo!("Shadowsocks deployed! remote: {ip}:{svr_port} local: 127.0.0.1:{port}");
    Ok(())
}

pub fn ss_proxy_config(cfg: &ShadowsocksConfig) -> anyhow::Result<()> {
    let ip = &cfg.ip;
    let port = cfg.local_port;
    sdebug!("ss_proxy_config ip={ip} port={port}");
    let cfg_dir = home_shadowsocks();
    let cfg_file = cfg_dir.join("config.json");

    ensure_cmd_or_install("sslocal", "shadowsocks-rust")?;
    std::fs::create_dir_all(&cfg_dir)?;

    let tmp = std::env::temp_dir().join(format!("ss_cfg_{}", std::process::id()));
    run_cmd::execute_and_wait(&RunConfig::new(
        "scp",
        &[
            "-o",
            "StrictHostKeyChecking=accept-new",
            "-o",
            "ConnectTimeout=10",
            &format!("root@{ip}:/etc/shadowsocks-rust/{ip}.json"),
            &tmp.to_string_lossy(),
        ],
    ))
    .map_err(|e| anyhow::anyhow!("scp from {ip} failed: {e}"))?;
    let raw = std::fs::read_to_string(&tmp)?;
    std::fs::remove_file(&tmp).ok();

    let mut v: serde_json::Value = serde_json::from_str(&raw)?;
    if let Some(obj) = v.as_object_mut() {
        obj.remove("mode");
    }
    v["server"] = serde_json::Value::String(ip.to_string());
    v["local_address"] = serde_json::Value::String("0.0.0.0".to_string());
    v["local_port"] = serde_json::json!(port);
    std::fs::write(&cfg_file, &serde_json::to_string_pretty(&v)?)?;
    sinfo!("config written to {}", cfg_file.display());

    bash_exec(&format!("sudo fuser -k {port}/tcp 2>/dev/null; true")).ok();
    bash_exec("pkill -f .sslocal. 2>/dev/null; true").ok();
    let log = cfg_dir.join("ss.log");
    bash_exec(&format!(
        "nohup sslocal -c {} > {} 2>&1 &",
        cfg_file.display(),
        log.display()
    ))?;
    std::thread::sleep(Duration::from_secs(2));
    let ok = bash_exec(&format!(
        "ss -tlnp 2>/dev/null | grep -q ':{port} ' && echo ok || echo fail"
    ))
    .unwrap_or_default();
    if ok.trim() != "ok" {
        let diag = bash_exec("pgrep -x sslocal 2>/dev/null && echo 'alive' || echo 'dead'")
            .unwrap_or_default();
        let tail = bash_exec(&format!(
            "tail -5 {} 2>/dev/null || echo 'no log'",
            log.display()
        ))
        .unwrap_or_default();
        serror!("sslocal not listening. process: {diag}, log: {tail}");
        anyhow::bail!("sslocal port {port} not ready");
    }
    sinfo!("sslocal listening on port {port}");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_ss_port() {
        assert_eq!(DEFAULT_SS_PORT, 1080u16);
    }

    #[test]
    fn test_default_ss_svr_port() {
        assert_eq!(DEFAULT_SS_SVR_PORT, 8388u16);
    }

    #[test]
    fn test_shadowsocks_config_new() {
        let cfg = ShadowsocksConfig::new("1.2.3.4");
        assert_eq!(cfg.ip, "1.2.3.4");
        assert_eq!(cfg.local_port, DEFAULT_SS_PORT);
        assert_eq!(cfg.server_port, DEFAULT_SS_SVR_PORT);
    }

    #[test]
    fn test_home_shadowsocks_returns_path() {
        let p = home_shadowsocks();
        assert!(p.ends_with(".config/shadowsocks"));
    }
}
