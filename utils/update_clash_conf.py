"""
Shadowsocks to Clash Configuration Converter
将 Shadowsocks 配置转换为 Clash 配置格式
"""

import json
import yaml
from pathlib import Path
from typing import Dict, Any, Union

class ClashConfigManager:
    """Clash 配置管理器"""
    
    @staticmethod
    def create_default_template(template_file: str) -> str:
        """创建默认 Clash 配置模板"""
        default_config = {
            "mixed-port": 7897,
            "allow-lan": True,
            "mode": "rule",
            "log-level": "info",
            "ipv6": False,
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
                    "proxies": ["DIRECT"]
                },
                {
                    "name": "Block",
                    "type": "select",
                    "proxies": ["REJECT"]
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
                "GEOIP,CN,DIRECT",
                "MATCH,Proxy"
            ]
        }
        
        Path(template_file).parent.mkdir(parents=True, exist_ok=True)
        with open(template_file, "w", encoding="utf-8") as f:
            yaml.dump(default_config, f, default_flow_style=False, allow_unicode=True)
        return template_file
    
    @staticmethod
    def load_config(template_file: str) -> Dict[str, Any]:
        """加载配置文件"""
        if not Path(template_file).exists():
            print(f"📝 模板不存在，创建: {template_file}")
            ClashConfigManager.create_default_template(template_file)
        
        with open(template_file, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    
    @staticmethod
    def save_config(config: Dict[str, Any], output_file: str):
        """保存配置文件"""
        Path(output_file).parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, "w", encoding="utf-8") as f:
            yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
    
    @staticmethod
    def add_proxy(config: Dict[str, Any], proxy: Dict[str, Any]):
        """添加代理节点到配置"""
        config["proxies"].append(proxy)
        
        for group in config["proxy-groups"]:
            if group["name"] == "Proxy":
                group["proxies"].append(proxy["name"])


def generate_clash_config(
    ss_config: Union[str, Dict],
    node_name: str = "🇯🇵 日本节点",
    template_file: str = "/tmp/clash_default_config.yaml",
    output_filename: str = "clash_config.yaml"
) -> str:
    """
    生成 Clash 配置文件
    
    Args:
        ss_config: SS配置(JSON字符串或字典)
        node_name: 节点名称
        template_file: 模板文件路径
        output_filename: 输出文件名
    
    Returns:
        生成的配置文件路径
    """
    # 转换 SS 节点
    converter = SSToClashConverter(ss_config, node_name)
    clash_proxy = converter.to_clash_proxy()
    
    # 加载配置
    config = ClashConfigManager.load_config(template_file)
    
    # 添加节点
    ClashConfigManager.add_proxy(config, clash_proxy)
    
    # 保存配置
    output_file = Path(template_file).parent / output_filename
    ClashConfigManager.save_config(config, str(output_file))
    
    return str(output_file)


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 3:
        print("用法: python update_clash_conf.py <ss_config_json> <node_name> [template_file]")
        print('示例: python update_clash_conf.py \'{"server":"1.2.3.4","server_port":8388,"password":"pass","method":"aes-256-gcm"}\' "🇺🇸 美国节点"')
        sys.exit(1)
    
    ss_config_json = sys.argv[1]
    node_name = sys.argv[2]
    template_file = sys.argv[3] if len(sys.argv) > 3 else "/tmp/clash_default_config.yaml"
    
    result = generate_clash_config(ss_config_json, node_name, template_file)
    print(f"✅ 配置文件已生成: {result}")
