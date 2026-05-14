//! WireGuard 服务端脚本部署
//!
//! 生成服务端配置脚本，通过 SCP 推送到远程执行，替代逐条 SSH 命令
//!
//! ============================
//! 入参说明
//! | 结构体/函数 | 入参 | 类型 | 说明 |
//! |-------------|------|------|------|
//! | ServerInfo | | | 服务端初始化结果 |
//! | ServerInfo.firewall | | String | 防火墙类型 |
//! | ServerInfo.server_priv | | String | 服务端私钥 |
//! | ServerInfo.server_pub | | String | 服务端公钥 |
//! | ServerInfo.iface | | String | 主网口名 |
//! | run_init | ip, port, wg_dir | &str, u16, &str | 推送 init 脚本并执行，返回服务端信息 |
//! | run_apply | ip, wg_dir, wg_name, iface, local_pub, server_priv, cfg | 多参 | 推送 apply 脚本并执行，完成服务端配置 |
//! | 返回 | | Result<ServerInfo>/Result<()> | 服务端信息/空 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! gen_init_script() -> bash 脚本 (本机生成):
//!   |- 1 detect firewall
//!   |- 2 install wireguard-tools
//!   |- 3 open firewall port
//!   |- 4 gen keys -> echo KEY=VALUE
//!   +- 5 get iface -> echo KEY=VALUE
//! run_init(ip, port, wg_dir):
//!   |- gen_init_script -> /tmp/wg_init_$$.sh
//!   |- cmd::scp -> root@ip:/tmp/
//!   |- cmd::ssh -> bash /tmp/wg_init.sh
//!   +- 解析 stdout 中 FIREWALL/SERVER_PRIV/SERVER_PUB/IFACE
//! gen_apply_script() -> bash 脚本 (本机生成):
//!   |- 1 enable ip forwarding
//!   |- 2 clean old wg interfaces
//!   |- 3 write server .conf (嵌入所有值)
//!   |- 4 chmod 600
//!   +- 5 systemctl enable+restart wg-quick
//! run_apply(ip, ...):
//!   |- gen_apply_script -> /tmp/wg_apply_$$.sh
//!   |- cmd::scp -> root@ip:/tmp/
//!   |- cmd::ssh -> bash /tmp/wg_apply.sh
//!   +- 失败时收集远程日志
//! 返回 -> ServerInfo / ()

use crate::{cmd, sdebug, serror, sinfo};
use anyhow::{Context, Result};
use std::fs;
use std::process;

use super::WireGuardConfig;

pub struct ServerInfo {
    pub firewall: String,
    pub server_priv: String,
    pub server_pub: String,
    pub iface: String,
}

fn gen_init_script(wg_dir: &str, port: u16) -> String {
    let script = r#"#!/bin/bash
set -e
WG_DIR="@WG_DIR@"
PORT=@PORT@

FW=$(command -v firewall-cmd &>/dev/null && echo firewalld || (command -v ufw &>/dev/null && echo ufw || (command -v nft &>/dev/null && echo nftables || echo iptables)))
echo "FIREWALL=$FW"

sudo pacman -S --noconfirm --needed wireguard-tools

case $FW in
    firewalld) sudo firewall-cmd --add-port=$PORT/udp --permanent && sudo firewall-cmd --reload ;;
    ufw) sudo ufw allow $PORT/udp ;;
    nftables) echo "WARN=nftables_open_port_manually" ;;
    *) sudo iptables -A INPUT -p udp --dport $PORT -j ACCEPT ; echo "WARN=iptables_not_persistent" ;;
esac

sudo mkdir -p "$WG_DIR"
WG_PRIV=$(sudo wg genkey)
WG_PUB=$(echo "$WG_PRIV" | sudo wg pubkey)
echo "$WG_PRIV" | sudo tee "$WG_DIR/privatekey" > /dev/null
echo "$WG_PUB" | sudo tee "$WG_DIR/publickey" > /dev/null
sudo chmod 600 "$WG_DIR/privatekey"
echo "SERVER_PRIV=$WG_PRIV"
echo "SERVER_PUB=$WG_PUB"

IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
echo "IFACE=$IFACE"
"#;

    script
        .replace("@WG_DIR@", wg_dir)
        .replace("@PORT@", &port.to_string())
}

fn gen_apply_script(args: &ApplyArgs) -> String {
    let script = r#"#!/bin/bash
set -e
CUR=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 0)
if [[ "$CUR" != "1" ]]; then
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl -p > /dev/null 2>&1
fi

sudo iptables -D FORWARD -i "@WG_NAME@" -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -o "@IFACE@" -j MASQUERADE 2>/dev/null || true
sudo wg show interfaces 2>/dev/null | xargs -r -I{} sudo wg-quick down {} 2>/dev/null || true
sudo wg show interfaces 2>/dev/null | xargs -r -I{} sudo ip link delete dev {} 2>/dev/null || true

SVR_CFG="@WG_DIR@/@WG_NAME@.conf"
sudo tee "$SVR_CFG" > /dev/null << WGEOF
[Interface]
Address = @TUNNEL_SERVER@/@SUBNET@
ListenPort = @PORT@
PrivateKey = @SERVER_PRIV@
PostUp = iptables -A FORWARD -i @WG_NAME@ -j ACCEPT || true; iptables -t nat -A POSTROUTING -o @IFACE@ -j MASQUERADE || true
PostDown = iptables -D FORWARD -i @WG_NAME@ -j ACCEPT || true; iptables -t nat -D POSTROUTING -o @IFACE@ -j MASQUERADE || true

[Peer]
PublicKey = @LOCAL_PUB@
AllowedIPs = @TUNNEL_CLIENT@/32
WGEOF

sudo chmod 600 "$SVR_CFG"
sudo systemctl enable "wg-quick@@WG_NAME@" && sudo systemctl restart "wg-quick@@WG_NAME@"
sudo wg show
"#;

    script
        .replace("@WG_DIR@", &args.wg_dir)
        .replace("@WG_NAME@", &args.wg_name)
        .replace("@IFACE@", &args.iface)
        .replace("@LOCAL_PUB@", &args.local_pub)
        .replace("@SERVER_PRIV@", &args.server_priv)
        .replace("@TUNNEL_CLIENT@", &args.tunnel_client)
        .replace("@TUNNEL_SERVER@", &args.tunnel_server)
        .replace("@SUBNET@", &args.subnet)
        .replace("@PORT@", &args.port.to_string())
}

struct ApplyArgs {
    wg_dir: String,
    wg_name: String,
    iface: String,
    local_pub: String,
    server_priv: String,
    tunnel_client: String,
    tunnel_server: String,
    subnet: String,
    port: u16,
}

pub fn run_init(ip: &str, port: u16, wg_dir: &str) -> Result<ServerInfo> {
    let script = gen_init_script(wg_dir, port);
    let local = format!("/tmp/wg_init_{}.sh", process::id());
    let remote = "/tmp/wg_init.sh";

    fs::write(&local, &script).with_context(|| format!("failed to write {local}"))?;
    cmd::scp(&local, &format!("root@{ip}:{remote}"))?;
    let output = cmd::ssh(&format!("root@{ip}"), &format!("bash {remote}"))?;
    let _ = fs::remove_file(&local);

    let mut info = ServerInfo {
        firewall: String::new(),
        server_priv: String::new(),
        server_pub: String::new(),
        iface: String::new(),
    };

    for line in output.lines() {
        if let Some((key, val)) = line.split_once('=') {
            match key {
                "FIREWALL" => info.firewall = val.to_string(),
                "SERVER_PRIV" => info.server_priv = val.to_string(),
                "SERVER_PUB" => info.server_pub = val.to_string(),
                "IFACE" => info.iface = val.to_string(),
                _ => {}
            }
        }
    }

    if info.server_priv.is_empty() || info.server_pub.is_empty() {
        anyhow::bail!("server init script failed: missing keys in output:\n{output}");
    }

    sinfo!("server firewall: {}", info.firewall);
    sdebug!("server iface={}", info.iface);
    Ok(info)
}

pub fn run_apply(
    ip: &str,
    wg_dir: &str,
    wg_name: &str,
    iface: &str,
    local_pub: &str,
    server_priv: &str,
    cfg: &WireGuardConfig,
) -> Result<()> {
    let args = ApplyArgs {
        wg_dir: wg_dir.to_string(),
        wg_name: wg_name.to_string(),
        iface: iface.to_string(),
        local_pub: local_pub.to_string(),
        server_priv: server_priv.to_string(),
        tunnel_client: cfg.tunnel_client_ip.clone(),
        tunnel_server: cfg.tunnel_server_ip.clone(),
        subnet: cfg.subnet.clone(),
        port: cfg.port,
    };

    let script = gen_apply_script(&args);
    let local = format!("/tmp/wg_apply_{}.sh", process::id());
    let remote = "/tmp/wg_apply.sh";

    fs::write(&local, &script).with_context(|| format!("failed to write {local}"))?;
    cmd::scp(&local, &format!("root@{ip}:{remote}"))?;

    cmd::ssh(&format!("root@{ip}"), &format!("bash {remote}")).map_err(|e| {
        let debug = cmd::ssh(
            &format!("root@{ip}"),
            &format!(
                "sudo systemctl status wg-quick@{wg_name} 2>&1 || true; \
                     echo '---'; \
                     sudo journalctl -xeu wg-quick@{wg_name} --no-pager 2>&1 | tail -20 || true"
            ),
        )
        .unwrap_or_default();
        let dmesg = cmd::ssh(
            &format!("root@{ip}"),
            "sudo dmesg | grep -i wireguard | tail -5 2>/dev/null || true",
        )
        .unwrap_or_default();
        serror!(
            "wg-quick@{wg_name} failed\n--- debug ---\n{}--- dmesg ---\n{}",
            debug,
            dmesg
        );
        anyhow::anyhow!("wg-quick@{wg_name} start failed: {e}")
    })?;

    let _ = fs::remove_file(&local);
    sdebug!("wg-quick@{wg_name} started");
    sinfo!("server wg-quick@{wg_name} enabled and restarted");
    Ok(())
}
