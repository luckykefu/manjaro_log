#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ OpenRouter AI + MCP 客户端 ]>>>>>>>>>>>>>>>
OpenRouter AI API 客户端，支持 MCP (Model Context Protocol) 工具调用
"""

from openai import OpenAI
import asyncio
import json
import os
from pathlib import Path
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
try:
    from .config import config, logger
except ImportError:
    from config import config, logger

class OpenRouterClient:
    """OpenRouter AI 客户端"""
    
    def __init__(self, api_key: str | None = None, model: str | None = None, base_url: str | None = None):
        self.api_key = api_key or config.get("openrouter.api_key")
        self.model = model or config.get('openrouter.model')
        self.base_url = base_url or config.get('openrouter.base_url')
        
        if not self.api_key or not self.model or not self.base_url:
            raise ValueError("API key, model or base_url not found")
        
        self.client = OpenAI(base_url=self.base_url, api_key=self.api_key)
        logger.debug(f"{self.model=}, {self.base_url=}")
    
    async def chat(self, prompt: str, tools: list | None = None, mcp_config_path: str | None = "~/.aws/amazonq/agents/default.json") -> str:
        # 如果提供 MCP 配置，加载 MCP 工具
        if mcp_config_path:
            mcp_config_path = os.path.expanduser(mcp_config_path)
            if not os.path.exists(mcp_config_path):
                logger.warning(f"MCP 配置文件不存在: {mcp_config_path}，使用普通聊天模式")
                mcp_config_path = None
        
        if mcp_config_path:
            with open(mcp_config_path) as f:
                mcp_configs = json.load(f).get("mcpServers", {})
            
            all_tools, sessions, contexts = [], [], []
            try:
                for name, cfg in mcp_configs.items():
                    try:
                        env = dict(os.environ)
                        env.update({k: os.path.expanduser(v) for k, v in cfg.get("env", {}).items()})
                        
                        stdio_ctx = stdio_client(StdioServerParameters(
                            command=cfg["command"], args=cfg.get("args", []), env=env
                        ))
                        read, write = await stdio_ctx.__aenter__()
                        contexts.append(stdio_ctx)
                        
                        session_ctx = ClientSession(read, write)
                        session = await session_ctx.__aenter__()
                        contexts.append(session_ctx)
                        
                        await session.initialize()
                        mcp_tools = await session.list_tools()
                        
                        all_tools.extend([{
                            "type": "function",
                            "function": {"name": t.name, "description": t.description, "parameters": t.inputSchema}
                        } for t in mcp_tools.tools])
                        
                        sessions.append((name, session))
                        logger.info(f"MCP 服务器 {name} 连接成功，加载 {len(mcp_tools.tools)} 个工具")
                    except Exception as e:
                        logger.warning(f"MCP 服务器 {name} 连接失败: {e}")
                
                if all_tools:
                    tools = all_tools
                else:
                    logger.warning("无可用 MCP 工具，使用普通聊天模式")
            finally:
                pass  # 稍后清理
        
        # 发送请求
        logger.debug(f"{prompt=}")
        kwargs = {"model": self.model, "messages": [{"role": "user", "content": prompt}]}
        if tools:
            kwargs.update({"tools": tools, "tool_choice": "auto"})
        
        response = self.client.chat.completions.create(**kwargs)
        message = response.choices[0].message
        
        # 处理 MCP 工具调用
        if mcp_config_path and message.tool_calls and sessions:
            messages = [{"role": "user", "content": prompt}, message]
            for tc in message.tool_calls:
                tool_result = None
                for name, session in sessions:
                    try:
                        result = await session.call_tool(tc.function.name, json.loads(tc.function.arguments))
                        if hasattr(result, 'content'):
                            if isinstance(result.content, list):
                                tool_result = '\n'.join([c.text if hasattr(c, 'text') else str(c) for c in result.content])
                            else:
                                tool_result = result.content.text if hasattr(result.content, 'text') else str(result.content)
                        else:
                            tool_result = str(result)
                        logger.info(f"工具 {tc.function.name} 执行成功")
                        break
                    except Exception as e:
                        logger.debug(f"工具调用失败: {e}")
                
                messages.append({"role": "tool", "tool_call_id": tc.id, "content": tool_result or "工具执行失败"})
            
            response = self.client.chat.completions.create(model=self.model, messages=messages)
            message = response.choices[0].message
        
        # 清理 MCP 资源
        if mcp_config_path and contexts:
            for ctx in reversed(contexts):
                try:
                    await ctx.__aexit__(None, None, None)
                except:
                    pass
        
        result = message.content or "无响应"
        logger.debug(f"{result=}")
        return result


if __name__ == "__main__":
    async def example_basic():
        """基础聊天示例"""
        logger.info("=== 基础聊天 ===")
        client = OpenRouterClient()
        result = await client.chat("你好，介绍一下你自己")
        logger.info(f"回复: {result}")

    # 运行示例
    asyncio.run(example_basic())