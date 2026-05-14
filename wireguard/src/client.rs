//! WireGuard 客户端配置 + SSH 密钥管理
//!
//! 管理本地 wireguard-tools 安装、密钥生成、客户端配置写入、启动与调试，
//! 以及服务端 SSH 公钥推送与双向密钥交换
//!
//! ============================
//! 入参说明
//! | 函数 | 入参 | 类型 | 说明 |
//! |------|------|------|------|
//! | ensure_tools | | | 确保本地已安装 wireguard-tools + openresolv |
//! | gen_keys | wg_dir | &str | 生成本地密钥对，返回公钥 |
//! | write_config | wg_dir, wg_name, server_pub, cfg | 多参 | 写入客户端 .conf |
//! | start_wg | wg_name | &str | 清理旧接口 + 启用 wg-quick |
//! | save_server_pubkey | wg_dir, server_pub | &str | 保存服务端公钥到本地 |
//! | push_key | ip | &str | ssh-copy-id 推送本地公钥到服务端 |
//! | key_exchange | ip | &str | 服务端生成密钥对，交换公钥到本地 |
//! | switch_wg | wg_name, wg_dir | &str, &str | 用已有配置连接服务端 |
//! | 返回 | | Result<String/()> | 密钥/空 |
//! =============================
//! ASCII图示处理逻辑:
//!
//! ensure_tools() -> which wg || pacman -S wireguard-tools
//! gen_keys(wg_dir) ->
//!   |- mkdir -p wg_dir
//!   +- wg genkey > privatekey && wg pubkey > publickey
//!   +- chmod 600 privatekey
//! write_config(wg_dir, wg_name, server_pub, cfg) ->
//!   |- 构建 [Interface] + [Peer] 配置块
//!   +- cat > {wg_dir}/{wg_name}.conf
//!   +- chmod 600
//! start_wg(wg_name) ->
//!   |- 清理已有 wg 接口
//!   +- systemctl enable + restart wg-quick@{wg_name}
//! save_server_pubkey(wg_dir, server_pub) ->
//!   +- echo server_pub > {wg_dir}/server_public_key
//! push_key(ip) ->
//!   |- ssh-keygen -R ip
//!   +- ssh-copy-id root@{ip}
//! key_exchange(ip) ->
//!   |- 服务端: ssh-keygen -t ed25519
//!   +- cat 服务端公钥 >> 本地 ~/.ssh/authorized_keys
//! switch_wg(wg_name, wg_dir) ->
//!   |- 检查 {wg_dir}/{wg_name}.conf 是否存在
//!   |- 清理旧 wg 接口
//!   +- systemctl enable + restart wg-quick@{wg_name}
//! 返回 -> 公钥字符串 / ()

use crate::cmd;
use crate::{sdebug, sinfo};
use anyhow::Result;

use super::WireGuardConfig;

pub fn ensure_tools() -> Result<()> {
    if cmd::run("which", &["wg"]).is_err() {
        cmd::sudo(&[
            "pacman",
            "-S",
            "--noconfirm",
            "--needed",
            "wireguard-tools",
            "openresolv",
        ])?;
        sinfo!("wireguard-tools openresolv installed");
    } else {
        sdebug!("wg already present");
    }
    Ok(())
}

pub fn gen_keys(wg_dir: &str) -> Result<String> {
    cmd::sudo(&["mkdir", "-p", wg_dir])?;
    cmd::sudo_bash_exec(
        "wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey",
    )?;
    cmd::sudo(&["chmod", "600", &format!("{wg_dir}/privatekey")])?;
    let local_pub = cmd::sudo(&["cat", &format!("{wg_dir}/publickey")])?;
    sinfo!("client key pair generated");
    sdebug!("client pubkey={}", &local_pub[..local_pub.len().min(16)]);
    Ok(local_pub)
}

pub fn write_config(
    wg_dir: &str,
    wg_name: &str,
    server_pub: &str,
    cfg: &WireGuardConfig,
) -> Result<()> {
    let local_priv = cmd::sudo(&["cat", &format!("{wg_dir}/privatekey")])?;
    let client_cfg = format!("{wg_dir}/{wg_name}.conf");
    let client_content = format!(
        "[Interface]\nAddress = {}/{}\nPrivateKey = {}\n\
         [Peer]\nPublicKey = {}\nEndpoint = {}:{}\nAllowedIPs = {}/32\nPersistentKeepalive = 25\n",
        cfg.tunnel_client_ip,
        cfg.subnet,
        local_priv.trim(),
        server_pub.trim(),
        cfg.server_ip,
        cfg.port,
        cfg.tunnel_server_ip,
    );
    sdebug!("client config: {client_cfg}");
    cmd::sudo_bash_exec(&format!(
        "cat > {client_cfg} << 'EOF'\n{}EOF\n",
        client_content
    ))?;
    cmd::sudo_ignore_output(&["chmod", "600", &client_cfg])?;
    sinfo!("client config written to {client_cfg}");
    Ok(())
}

pub fn start_wg(wg_name: &str) -> Result<()> {
    cmd::sudo(&["pacman", "-S", "--noconfirm", "--needed", "openresolv"])?;
    cmd::bash_exec(&format!(
        "sudo wg show interfaces 2>/dev/null | xargs -r -I{{}} sh -c 'sudo systemctl stop wg-quick@{{}} 2>/dev/null; sudo wg-quick down {{}} 2>/dev/null; sudo ip link delete dev {{}} 2>/dev/null' || true",
    ))
    .ok();
    cmd::sudo(&["systemctl", "enable", &format!("wg-quick@{wg_name}")])?;
    cmd::sudo(&["systemctl", "restart", &format!("wg-quick@{wg_name}")])?;
    let local_wg = cmd::sudo(&["wg", "show"])?;
    sdebug!("local wg:\n{}", local_wg);
    sinfo!("client wg-quick@{wg_name} restarted");
    Ok(())
}

pub fn save_server_pubkey(wg_dir: &str, server_pub: &str) -> Result<()> {
    cmd::sudo_bash_exec(&format!(
        "echo '{}' > {wg_dir}/server_public_key",
        server_pub.trim()
    ))?;
    sinfo!("server public key saved");
    Ok(())
}

pub fn push_key(ip: &str) -> Result<()> {
    sdebug!("push_key ip={ip}");
    cmd::run("ssh-keygen", &["-R", ip]).ok();
    cmd::bash_exec(&format!(
        "ssh-copy-id -o StrictHostKeyChecking=accept-new -i ~/.ssh/id_ed25519.pub root@{ip}"
    ))
    .map_err(|e| anyhow::anyhow!("ssh-copy-id failed: {e}, push manually"))?;
    sinfo!("SSH public key copied to root@{ip}");
    Ok(())
}

pub fn key_exchange(ip: &str) -> Result<()> {
    sdebug!("key_exchange ip={ip}");
    cmd::ssh(
        &format!("root@{ip}"),
        "sudo pacman -S --noconfirm --needed sshpass",
    )
    .ok();
    cmd::ssh(
        &format!("root@{ip}"),
        "ssh-keygen -t ed25519 -C \"\" -f \"$HOME/.ssh/id_ed25519\" -N \"\" 2>/dev/null || true",
    )
    .ok();
    let remote_pubkey = cmd::ssh(&format!("root@{ip}"), "cat ~/.ssh/id_ed25519.pub")?;
    cmd::bash_exec(&format!(
        "echo '{}' >> ~/.ssh/authorized_keys",
        remote_pubkey.trim()
    ))?;
    sinfo!("server SSH key added to local authorized_keys");
    Ok(())
}

pub fn switch_wg(wg_name: &str, wg_dir: &str) -> Result<()> {
    let config_path = format!("{wg_dir}/{wg_name}.conf");
    if !std::path::Path::new(&config_path).exists() {
        anyhow::bail!("config not found: {config_path}, deploy first");
    }
    sdebug!("switch_wg {config_path}");

    cmd::bash_exec(&format!(
        "sudo wg show interfaces 2>/dev/null | xargs -r -I{{}} sh -c 'sudo systemctl stop wg-quick@{{}} 2>/dev/null; sudo wg-quick down {{}} 2>/dev/null; sudo ip link delete dev {{}} 2>/dev/null' || true",
    ))
    .ok();
    cmd::sudo(&["systemctl", "enable", &format!("wg-quick@{wg_name}")])?;
    cmd::sudo(&["systemctl", "restart", &format!("wg-quick@{wg_name}")])?;
    let status = cmd::sudo(&["wg", "show"])?;
    sdebug!("wg status:\n{status}");
    sinfo!("wg-quick@{wg_name} started");
    Ok(())
}
