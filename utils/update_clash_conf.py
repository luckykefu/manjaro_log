# ============================================================================
# Script: update_clash_conf.py
# Description: Convert Shadowsocks config to Clash config format
# Logic: Creates default Clash template with proxy groups and rules,
#        converts Shadowsocks JSON to Clash proxy format, merges into template,
#        generates complete Clash YAML configuration file
# ============================================================================
# 脚本: update_clash_conf.py
# 描述: 将 Shadowsocks 配置转换为 Clash 配置格式
# 逻辑: 创建包含代理组和规则的默认 Clash 模板，将 Shadowsocks JSON 转换为
#        Clash 代理格式，合并到模板，生成完整的 Clash YAML 配置文件
# ============================================================================

import yaml
import json
from pathlib import Path

def create_default_clash_config(template_file):
    """创建默认的Clash配置模板"""
    default_config = {
    "port": 7890,
    "socks-port": 7891,
    "mixed-port": 7890,
    "allow-lan": true,
    "mode": "rule",
    "log-level": "info",
    "ipv6": false,
    "external-controller": "127.0.0.1:9090",
    "external-ui": "dashboard",
    "proxies": [],
    "proxy-groups": [
        {
            "name": "Proxy",
            "type": "url-test",
            "url": "http://cp.cloudflare.com/generate_204",
            "interval": 300,
            "tolerance": 50,
            "proxies": []
        },
        {
            "name": "Direct",
            "type": "select",
            "proxies": [
                "DIRECT"
            ]
        },
        {
            "name": "Block",
            "type": "select",
            "proxies": [
                "REJECT"
            ]
        }
    ],
    "rules": [
        "DOMAIN-SUFFIX,local,DIRECT",
        "IP-CIDR,127.0.0.0/8,DIRECT",
        "IP-CIDR,10.0.0.0/8,DIRECT",
        "IP-CIDR,172.16.0.0/12,DIRECT",
        "IP-CIDR,192.168.0.0/16,DIRECT",
        "IP-CIDR,100.64.0.0/10,DIRECT",
        "DOMAIN-KEYWORD,adservice,REJECT",
        "DOMAIN-SUFFIX,doubleclick.net,REJECT",
        "DOMAIN-SUFFIX,googlesyndication.com,REJECT",
        "DOMAIN-SUFFIX,googleadservices.com,REJECT",
        "DOMAIN-SUFFIX,adsystem.com,REJECT",
        "GEOIP,CN,DIRECT",
        "MATCH,Proxy"
    ]
}


    Path(template_file).parent.mkdir(parents=True, exist_ok=True)
    with open(template_file, "w", encoding="utf-8") as f:
        yaml.dump(default_config, f, default_flow_style=False, allow_unicode=True)
    return template_file

def trans_ss2clash(ss_config_json, node_name):
    """将Shadowsocks配置转换为Clash配置"""
    if isinstance(ss_config_json, str):
        ss_config = json.loads(ss_config_json)
    else:
        ss_config = ss_config_json

    return {
        "name": node_name,
        "type": "ss",
        "server": ss_config["server"],
        "port": ss_config["server_port"],
        "cipher": ss_config["method"],
        "password": ss_config["password"],
        "udp": True
    }

def generate_clash_config(ss_config_json, node_name="🇯🇵 日本节点", 
                         template_file="/tmp/clash_default_config.yaml",
                         output_filename="clash_config.yaml"):
    """将Shadowsocks配置转换为完整的Clash配置文件"""

    if not Path(template_file).exists():
        print(f"📝 模板文件不存在，正在创建: {template_file}")
        create_default_clash_config(template_file)

    with open(template_file, "r", encoding="utf-8") as f:
        clash_config = yaml.safe_load(f)

    clash_node = trans_ss2clash(ss_config_json, node_name)
    clash_config["proxies"].append(clash_node)

    for group in clash_config["proxy-groups"]:
        if group["name"] == "Proxy":
            group["proxies"].append(clash_node["name"])

    # 输出文件在模板文件的同一目录下
    output_file = Path(template_file).parent / output_filename
    output_file.parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        yaml.dump(clash_config, f, default_flow_style=False, allow_unicode=True)

    return str(output_file)


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python script.py <ss_config_json> <node_name> [template_file]")
        print("Example: python script.py '{\"server\":\"1.2.3.4\",\"server_port\":8388,\"password\":\"pass\",\"method\":\"aes-256-gcm\"}' '🇺🇸 美国节点' '/path/to/template.yaml'")
        sys.exit(1)

    ss_config_json = sys.argv[1]
    node_name = sys.argv[2]
    template_file = sys.argv[3] if len(sys.argv) > 3 else "/tmp/clash_default_config.yaml"

    result = generate_clash_config(ss_config_json, node_name, template_file=template_file)
    print(f"✅ 配置文件已生成: {result}")

    # ss_config_json = """
    # {
    #     "server": "112.50.9.42",
    #     "server_port": 8388,
    #     "password": "11111111",
    #     "method": "aes-256-gcm"
    # }
    # """
    # # python script.py <ss_config_json> <node_name> [template_file]
    # result = generate_clash_config(ss_config_json, "🇺🇸 美国节点", "/tmp/clash_default_config.yaml")
    # print(f"✅ 配置文件已生成: {result}")

