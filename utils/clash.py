"""SS 配置转 Clash yaml 工具
用法: python clash.py <IP> <ss_config_json> [节点名] [输出文件]
"""
import json
import sys
import yaml
from pathlib import Path

DEFAULT_RULES = [
    "DOMAIN-SUFFIX,local,DIRECT",
    "IP-CIDR,127.0.0.0/8,DIRECT",
    "IP-CIDR,192.168.0.0/16,DIRECT",
    "DOMAIN-SUFFIX,cn,DIRECT",
    "DOMAIN-KEYWORD,baidu,DIRECT",
    "GEOIP,CN,DIRECT",
    "MATCH,Proxy",
]

def generate(ip: str, ss_config: dict, node: str = "SS节点", out: str = "/tmp/clash_config.yaml"):
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
    if len(sys.argv) < 3:
        print("用法: python clash.py <IP> <ss_config_json> [节点名] [输出文件]")
        sys.exit(1)
    generate(
        ip=sys.argv[1],
        ss_config=json.loads(sys.argv[2]),
        node=sys.argv[3] if len(sys.argv) > 3 else "SS节点",
        out=sys.argv[4] if len(sys.argv) > 4 else "/tmp/clash_config.yaml",
    )
