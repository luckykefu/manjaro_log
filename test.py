import json
import asyncio
import ollama
from typing import Dict, List, Any, Optional
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


class MCPServerManager:
    """MCP 服务器管理器"""
    
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.servers: Dict[str, Dict] = {}
        self.sessions: Dict[str, ClientSession] = {}
        self.tools: List[Dict] = []
        
    def load_config(self):
        """从 JSON 文件加载 MCP 服务器配置"""
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            self.servers = {
                name: server 
                for name, server in config.get('mcpServers', {}).items()
                if not server.get('disabled', False)
            }
        print(f"已加载 {len(self.servers)} 个 MCP 服务器")
        
    async def connect_server(self, name: str, server_config: Dict):
        """连接单个 MCP 服务器"""
        try:
            server_params = StdioServerParameters(
                command=server_config['command'],
                args=server_config.get('args', []),
                env=server_config.get('env', None)
            )
            
            read, write = await stdio_client(server_params).__aenter__()
            session = await ClientSession(read, write).__aenter__()
            await session.initialize()
            
            self.sessions[name] = session
            
            # 获取该服务器的工具列表
            tools_response = await session.list_tools()
            server_tools = tools_response.tools if hasattr(tools_response, 'tools') else []
            
            for tool in server_tools:
                self.tools.append({
                    'server': name,
                    'name': tool.name,
                    'description': tool.description,
                    'schema': tool.inputSchema
                })
            
            print(f"✓ 已连接 {name},发现 {len(server_tools)} 个工具")
            return True
            
        except Exception as e:
            print(f"✗ 连接 {name} 失败: {e}")
            return False
    
    async def connect_all_servers(self):
        """连接所有启用的 MCP 服务器"""
        tasks = [
            self.connect_server(name, config)
            for name, config in self.servers.items()
        ]
        await asyncio.gather(*tasks, return_exceptions=True)
        print(f"\n共发现 {len(self.tools)} 个可用工具")
    
    def get_ollama_tools_format(self) -> List[Dict]:
        """将 MCP 工具转换为 Ollama 工具格式"""
        ollama_tools = []
        for tool in self.tools:
            ollama_tools.append({
                'type': 'function',
                'function': {
                    'name': f"{tool['server']}_{tool['name']}",
                    'description': tool['description'],
                    'parameters': tool['schema']
                }
            })
        return ollama_tools
    
    async def call_tool(self, server_name: str, tool_name: str, arguments: Dict) -> Any:
        """调用指定的 MCP 工具"""
        if server_name not in self.sessions:
            raise ValueError(f"服务器 {server_name} 未连接")
        
        session = self.sessions[server_name]
        result = await session.call_tool(tool_name, arguments)
        return result
    
    async def close_all(self):
        """关闭所有连接"""
        for name, session in self.sessions.items():
            try:
                await session.__aexit__(None, None, None)
                print(f"已关闭 {name}")
            except:
                pass


class OllamaMCPChat:
    """Ollama + MCP 智能对话系统"""
    
    def __init__(self, mcp_manager: MCPServerManager, model: str = 'llama3.2:3b'):
        self.mcp_manager = mcp_manager
        self.model = model
        self.messages: List[Dict] = []
    
    async def chat(self, user_message: str) -> str:
        """与 Ollama 对话,自动调用 MCP 工具"""
        self.messages.append({
            'role': 'user',
            'content': user_message
        })
        
        # 获取工具列表
        tools = self.mcp_manager.get_ollama_tools_format()
        
        max_iterations = 5  # 防止无限循环
        iteration = 0
        
        while iteration < max_iterations:
            iteration += 1
            
            # 调用 Ollama
            response = ollama.chat(
                model=self.model,
                messages=self.messages,
                tools=tools if tools else None
            )
            
            assistant_message = response['message']
            self.messages.append(assistant_message)
            
            # 检查是否有工具调用
            if not assistant_message.get('tool_calls'):
                # 没有工具调用,返回最终答案
                return assistant_message['content']
            
            # 处理工具调用
            for tool_call in assistant_message['tool_calls']:
                function_name = tool_call['function']['name']
                arguments = tool_call['function']['arguments']
                
                print(f"\n🔧 调用工具: {function_name}")
                print(f"   参数: {arguments}")
                
                # 解析服务器名称和工具名称
                parts = function_name.split('_', 1)
                if len(parts) == 2:
                    server_name, tool_name = parts
                    
                    try:
                        # 调用 MCP 工具
                        result = await self.mcp_manager.call_tool(
                            server_name, 
                            tool_name, 
                            arguments
                        )
                        
                        # 将工具结果添加到消息历史
                        self.messages.append({
                            'role': 'tool',
                            'content': str(result)
                        })
                        
                        print(f"   ✓ 工具执行成功")
                        
                    except Exception as e:
                        error_msg = f"工具执行失败: {str(e)}"
                        print(f"   ✗ {error_msg}")
                        self.messages.append({
                            'role': 'tool',
                            'content': error_msg
                        })
        
        return "达到最大迭代次数,对话结束"


async def main():
    """主函数示例"""
    
    # 1. 创建 MCP 管理器并加载配置
    manager = MCPServerManager('.amazonq/agents/default.json')
    manager.load_config()
    
    # 2. 连接所有 MCP 服务器
    await manager.connect_all_servers()
    
    # 3. 创建聊天实例
    chat = OllamaMCPChat(manager)
    
    # 4. 开始对话
    print("\n" + "="*50)
    print("Ollama + MCP 智能助手已启动")
    print("="*50 + "\n")
    
    try:
        # 示例对话
        questions = [
            "帮我查询数据库中的表结构",
            "打开浏览器访问 https://www.example.com",
            "创建一个简单的流程图"
        ]
        
        for question in questions:
            print(f"\n👤 用户: {question}")
            response = await chat.chat(question)
            print(f"\n🤖 助手: {response}")
            print("\n" + "-"*50)
        
        # 交互模式
        # while True:
        #     user_input = input("\n👤 你: ")
        #     if user_input.lower() in ['exit', 'quit', '退出']:
        #         break
        #     
        #     response = await chat.chat(user_input)
        #     print(f"\n🤖 助手: {response}")
        
    finally:
        # 5. 清理资源
        await manager.close_all()


if __name__ == "__main__":
    # 运行主程序
    asyncio.run(main())
