"""SS 配置转 Clash yaml 工具
用法: uv run clash.py <ip> [remote_cfg=/etc/shadowsocks-rust/config.json] [节点名] [输出文件]
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

DEFAULT_RULES = [
    "DOMAIN-SUFFIX,local,DIRECT",
    "IP-CIDR,127.0.0.0/8,DIRECT",
    "IP-CIDR,192.168.0.0/16,DIRECT",
    "DOMAIN-SUFFIX,cn,DIRECT",
    "DOMAIN-KEYWORD,baidu,DIRECT",
    "GEOIP,CN,DIRECT",
    "MATCH,Proxy",
]

REMOTE_CFG = "/etc/shadowsocks-rust/config.json"


def fetch(ip: str, remote_cfg: str = REMOTE_CFG) -> dict:
    """scp 拉取远程 ss 配置文件，返回解析后的 dict"""
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        tmp = f.name
    subprocess.run(["scp", f"root@{ip}:{remote_cfg}", tmp], check=True)
    return json.loads(Path(tmp).read_text())


def generate(ip: str, ss_config: dict, node: str = "SS节点", out: str = "/tmp/clash_config.yaml") -> str:
    """ss_config 转 clash yaml，写入 out 路径"""
    proxy = {
        "name": node, "type": "ss",
        "server": ip,
        "port": ss_config["server_port"],
        "cipher": ss_config["method"],
        "password": ss_config["password"],
        "udp": True,
    }
    config = {
        "mixed-port": 7897,
        "allow-lan": True,
        "mode": "rule",
        "log-level": "info",
        "external-controller": "127.0.0.1:9090",
        "proxies": [proxy],
        "proxy-groups": [
            {"name": "Proxy", "type": "url-test", "proxies": [node],
             "url": "http://cp.cloudflare.com/generate_204", "interval": 300},
        ],
        "rules": DEFAULT_RULES,
    }
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text(yaml.dump(config, allow_unicode=True), encoding="utf-8")
    print(f"✅ 已生成: {out}")
    return out


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: uv run clash.py <ip> [remote_cfg] [节点名] [输出文件]")
        sys.exit(1)
    _ip = sys.argv[1]
    _cfg = fetch(_ip, sys.argv[2] if len(sys.argv) > 2 else REMOTE_CFG)
    generate(
        ip=_ip,
        ss_config=_cfg,
        node=sys.argv[3] if len(sys.argv) > 3 else "SS节点",
        out=sys.argv[4] if len(sys.argv) > 4 else "/tmp/clash_config.yaml",
    )
