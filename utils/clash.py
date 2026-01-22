"""Clash 配置工具 - Shadowsocks 节点转换与配置管理"""

import json
import yaml
from pathlib import Path
from typing import Dict, Any, Optional, Union


class SSToClash:
    """Shadowsocks 配置转 Clash 节点"""
    
    def __init__(self, ss_config: Dict[str, Any], ip: Optional[str] = None, node_name: str = "SS节点"):
        """
        Args:
            ss_config: SS服务器配置
            ip: 服务器IP (可选，覆盖配置中的 server)
            node_name: 节点名称
        """
        self.ss_config = ss_config.copy()
        if ip:
            self.ss_config["server"] = ip
        self.node_name = node_name
    
    def to_clash_node(self) -> Dict[str, Any]:
        """转换为 Clash 节点格式"""
        return {
            "name": self.node_name,
            "type": "ss",
            "server": self.ss_config["server"],
            "port": self.ss_config["server_port"],
            "cipher": self.ss_config["method"],
            "password": self.ss_config["password"],
            "udp": True
        }


class ClashConfigManager:
    """Clash 配置管理器"""
    
    DEFAULT_CONFIG = {
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
            {"name": "Direct", "type": "select", "proxies": ["DIRECT"]},
            {"name": "Block", "type": "select", "proxies": ["REJECT"]}
        ],
        "rules": [
            "DOMAIN-SUFFIX,local,DIRECT",
            "IP-CIDR,127.0.0.0/8,DIRECT",
            "IP-CIDR,10.0.0.0/8,DIRECT",
            "IP-CIDR,172.16.0.0/12,DIRECT",
            "IP-CIDR,192.168.0.0/16,DIRECT",
            "IP-CIDR,100.64.0.0/10,DIRECT",
            "DOMAIN-KEYWORD,adservice,REJECT",
            "DOMAIN-KEYWORD,analytics,REJECT",
            "DOMAIN-SUFFIX,doubleclick.net,REJECT",
            "DOMAIN-SUFFIX,googlesyndication.com,REJECT",
            "DOMAIN-SUFFIX,cn,DIRECT",
            "DOMAIN-KEYWORD,baidu,DIRECT",
            "DOMAIN-KEYWORD,alipay,DIRECT",
            "DOMAIN-KEYWORD,taobao,DIRECT",
            "GEOIP,CN,DIRECT",
            "MATCH,Proxy"
        ]
    }
    
    @classmethod
    def create_template(cls, template_file: str) -> str:
        """创建默认配置模板"""
        Path(template_file).parent.mkdir(parents=True, exist_ok=True)
        with open(template_file, "w", encoding="utf-8") as f:
            yaml.dump(cls.DEFAULT_CONFIG, f, default_flow_style=False, allow_unicode=True)
        return template_file
    
    @classmethod
    def load(cls, template_file: str) -> Dict[str, Any]:
        """加载配置"""
        if not Path(template_file).exists():
            print(f"📝 创建模板: {template_file}")
            cls.create_template(template_file)
        
        with open(template_file, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    
    @staticmethod
    def save(config: Dict[str, Any], output_file: str):
        """保存配置"""
        Path(output_file).parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, "w", encoding="utf-8") as f:
            yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
    
    @staticmethod
    def add_proxy(config: Dict[str, Any], proxy: Dict[str, Any]):
        """添加代理节点"""
        config["proxies"].append(proxy)
        for group in config["proxy-groups"]:
            if group["name"] == "Proxy":
                group["proxies"].append(proxy["name"])


def generate_clash_config(
    ss_config: Union[str, Dict],
    ip: Optional[str] = None,
    node_name: str = "SS节点",
    template_file: str = "/tmp/clash_config.yaml",
    output_file: Optional[str] = None
) -> str:
    """
    生成 Clash 配置文件
    
    Args:
        ss_config: SS配置(JSON字符串或字典)
        ip: 服务器IP (可选)
        node_name: 节点名称
        template_file: 模板文件路径
        output_file: 输出文件路径 (默认与模板同目录)
    
    Returns:
        生成的配置文件路径
    """
    # 解析配置
    if isinstance(ss_config, str):
        ss_config = json.loads(ss_config)
    
    # 转换节点
    converter = SSToClash(ss_config, ip, node_name)
    clash_node = converter.to_clash_node()
    
    # 加载并更新配置
    config = ClashConfigManager.load(template_file)
    ClashConfigManager.add_proxy(config, clash_node)
    
    # 保存
    if not output_file:
        output_file = str(Path(template_file).parent / "clash_config.yaml")
    ClashConfigManager.save(config, output_file)
    
    return output_file


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("用法: python clash.py <ss_config_json> [ip] [node_name] [template_file]")
        print('示例: python clash.py \'{"server":"0.0.0.0","server_port":8388,"password":"pass","method":"aes-256-gcm"}\' 1.2.3.4 "Tokyo"')
        sys.exit(1)
    
    ss_config = sys.argv[1]
    ip = sys.argv[2] if len(sys.argv) > 2 else None
    node_name = sys.argv[3] if len(sys.argv) > 3 else "SS节点"
    template = sys.argv[4] if len(sys.argv) > 4 else "/tmp/clash_config.yaml"
    
    result = generate_clash_config(ss_config, ip, node_name, template)
    print(f"✅ 配置已生成: {result}")
