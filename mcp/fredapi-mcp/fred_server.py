#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ FRED API MCP Server ]>>>>>>>>>>>>>>>
"""

from mcp.server import Server
from mcp.types import Tool, TextContent
import mcp.server.stdio
from fredapi import Fred
import os


# >>>>>>>>>>>>>>>>>>>>[ 创建服务器 ]>>>>>>>>>>>>>>>
app = Server("fred-api")
fred = Fred(api_key=os.getenv("FRED_API_KEY", "your_api_key_here"))


# >>>>>>>>>>>>>>>>>>>>[ 注册 Tool ]>>>>>>>>>>>>>>>
@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="get_series",
            description="获取 FRED 经济数据序列",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string", "description": "数据序列 ID (如 GDP, UNRATE)"},
                    "observation_start": {"type": "string", "description": "开始日期 (YYYY-MM-DD)"},
                    "observation_end": {"type": "string", "description": "结束日期 (YYYY-MM-DD)"}
                },
                "required": ["series_id"]
            }
        ),
        Tool(
            name="get_series_info",
            description="获取数据序列的详细信息（标题、频率、单位等）",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string", "description": "数据序列 ID"}
                },
                "required": ["series_id"]
            }
        ),
        Tool(
            name="search",
            description="全文搜索 FRED 数据序列",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "搜索关键词"},
                    "limit": {"type": "integer", "description": "返回结果数量", "default": 10}
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="get_series_all_releases",
            description="获取数据序列的所有发布版本（包括修订）",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string", "description": "数据序列 ID"},
                    "limit": {"type": "integer", "description": "返回数据点数量", "default": 20}
                },
                "required": ["series_id"]
            }
        ),
        Tool(
            name="get_series_first_release",
            description="获取数据序列的首次发布版本（忽略修订）",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string", "description": "数据序列 ID"}
                },
                "required": ["series_id"]
            }
        ),
        Tool(
            name="get_series_as_of_date",
            description="获取数据序列在特定日期的数据（包括该日期前的修订）",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string", "description": "数据序列 ID"},
                    "as_of_date": {"type": "string", "description": "截止日期 (YYYY-MM-DD)"}
                },
                "required": ["series_id", "as_of_date"]
            }
        ),
        Tool(
            name="get_series_vintage_dates",
            description="获取数据序列的所有修订日期",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string", "description": "数据序列 ID"}
                },
                "required": ["series_id"]
            }
        ),
        Tool(
            name="search_by_release",
            description="按发布 ID 搜索数据序列",
            inputSchema={
                "type": "object",
                "properties": {
                    "release_id": {"type": "integer", "description": "发布 ID (如 151)"},
                    "limit": {"type": "integer", "description": "返回结果数量", "default": 10}
                },
                "required": ["release_id"]
            }
        ),
        Tool(
            name="search_by_category",
            description="按分类 ID 搜索数据序列",
            inputSchema={
                "type": "object",
                "properties": {
                    "category_id": {"type": "integer", "description": "分类 ID (如 125=贸易平衡)"},
                    "limit": {"type": "integer", "description": "返回结果数量", "default": 10}
                },
                "required": ["category_id"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "get_series":
        series_id = arguments["series_id"]
        obs_start = arguments.get("observation_start")
        obs_end = arguments.get("observation_end")
        
        try:
            data = fred.get_series(series_id, observation_start=obs_start, observation_end=obs_end)
            result = f"数据序列 {series_id}:\n{data.tail(10).to_string()}"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "get_series_info":
        series_id = arguments["series_id"]
        
        try:
            info = fred.get_series_info(series_id)
            result = f"数据序列 {series_id} 信息:\n"
            result += f"- 标题: {info.get('title')}\n"
            result += f"- 频率: {info.get('frequency')}\n"
            result += f"- 单位: {info.get('units')}\n"
            result += f"- 开始日期: {info.get('observation_start')}\n"
            result += f"- 结束日期: {info.get('observation_end')}"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "search":
        text = arguments["text"]
        limit = arguments.get("limit", 10)
        
        try:
            results = fred.search(text, limit=limit)
            result = f"搜索 '{text}' 找到 {len(results)} 条结果:\n"
            for _, row in results.iterrows():
                result += f"- {row['id']}: {row['title']}\n"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "get_series_all_releases":
        series_id = arguments["series_id"]
        limit = arguments.get("limit", 20)
        
        try:
            data = fred.get_series_all_releases(series_id)
            result = f"数据序列 {series_id} 所有版本 (最近 {limit} 条):\n"
            result += data.tail(limit).to_string()
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "get_series_first_release":
        series_id = arguments["series_id"]
        
        try:
            data = fred.get_series_first_release(series_id)
            result = f"数据序列 {series_id} 首次发布:\n{data.tail(10).to_string()}"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "get_series_as_of_date":
        series_id = arguments["series_id"]
        as_of_date = arguments["as_of_date"]
        
        try:
            data = fred.get_series_as_of_date(series_id, as_of_date)
            result = f"数据序列 {series_id} 截至 {as_of_date}:\n{data.tail(10).to_string()}"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "get_series_vintage_dates":
        series_id = arguments["series_id"]
        
        try:
            dates = fred.get_series_vintage_dates(series_id)
            result = f"数据序列 {series_id} 修订日期 ({len(dates)} 个):\n"
            result += "\n".join([str(d) for d in dates[-20:]])
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "search_by_release":
        release_id = arguments["release_id"]
        limit = arguments.get("limit", 10)
        
        try:
            results = fred.search_by_release(release_id, limit=limit)
            result = f"发布 {release_id} 下的数据序列 ({len(results)} 条):\n"
            for _, row in results.iterrows():
                result += f"- {row['id']}: {row['title']}\n"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]
    
    elif name == "search_by_category":
        category_id = arguments["category_id"]
        limit = arguments.get("limit", 10)
        
        try:
            results = fred.search_by_category(category_id, limit=limit)
            result = f"分类 {category_id} 下的数据序列 ({len(results)} 条):\n"
            for _, row in results.iterrows():
                result += f"- {row['id']}: {row['title']}\n"
        except Exception as e:
            result = f"错误: {str(e)}"
            
        return [TextContent(type="text", text=result)]


# >>>>>>>>>>>>>>>>>>>>[ 启动服务器 ]>>>>>>>>>>>>>>>
async def main():
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
