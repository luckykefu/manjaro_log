# FRED API MCP 服务器开发教程

将 FRED (Federal Reserve Economic Data) API 封装为 MCP 服务器


## 1. 环境准备


```python
# 安装 uv 包管理器
!sudo pacman -S --needed --noconfirm uv
```

```python
# 切换到工作目录
%cd /data/projects_ING/crypto_quant/.manjaro/mcp
```

## 2. 初始化项目


```python
# 创建 MCP 服务器项目
!uv init fredapi-mcp
```

```python
%cd fredapi-mcp
```

## 3. 配置国内镜像


```bash
%%bash
mkdir -p ~/.config/uv && cat > ~/.config/uv/uv.toml << 'EOF'
[pip]
index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"
EOF
```

## 4. 安装依赖


```python
# 安装 MCP 和 FRED API 依赖
!uv add "mcp[cli]" fredapi 
```

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ MCP 服务器 ]>>>>>>>>>>>>>>>
"""

from mcp.server import Server
from mcp.types import Tool, Resource, Prompt, TextContent
import mcp.server.stdio
from fredapi import Fred
import os


# >>>>>>>>>>>>>>>>>>>>[ 初始化 ]>>>>>>>>>>>>>>>
app = Server("fred-api")
fred = Fred(api_key=os.getenv("FRED_API_KEY"))


# >>>>>>>>>>>>>>>>>>>>[ Tools 层 ]>>>>>>>>>>>>>>>
@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="get_series",
            description="获取经济数据",
            inputSchema={
                "type": "object",
                "properties": {
                    "series_id": {"type": "string"}
                },
                "required": ["series_id"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "get_series":
        data = fred.get_series(arguments["series_id"])
        return [TextContent(type="text", text=str(data))]


# >>>>>>>>>>>>>>>>>>>>[ Resources 层 ]>>>>>>>>>>>>>>>
@app.list_resources()
async def list_resources() -> list[Resource]:
    return [
        Resource(
            uri="fred://categories",
            name="FRED 分类列表",
            mimeType="application/json"
        )
    ]


@app.read_resource()
async def read_resource(uri: str) -> str:
    if uri == "fred://categories":
        return '{"categories": ["GDP", "Employment"]}'


# >>>>>>>>>>>>>>>>>>>>[ Prompts 层 ]>>>>>>>>>>>>>>>
@app.list_prompts()
async def list_prompts() -> list[Prompt]:
    return [
        Prompt(
            name="analyze_gdp",
            description="分析 GDP 数据"
        )
    ]


@app.get_prompt()
async def get_prompt(name: str, arguments: dict) -> str:
    if name == "analyze_gdp":
        return "请分析以下 GDP 数据趋势..."


# >>>>>>>>>>>>>>>>>>>>[ 启动服务器 ]>>>>>>>>>>>>>>>
async def main():
    async with mcp.server.stdio.stdio_server() as (read, write):
        await app.run(read, write, app.create_initialization_options())


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

```python
```

## 5. MCP 服务器已创建

服务器文件：`fred_server.py`

### 可用工具 (9个)

1. **get_series** - 获取经济数据序列
2. **get_series_info** - 获取序列详细信息
3. **search** - 全文搜索数据序列
4. **get_series_all_releases** - 获取所有发布版本
5. **get_series_first_release** - 获取首次发布版本
6. **get_series_as_of_date** - 获取特定日期数据
7. **get_series_vintage_dates** - 获取修订日期列表
8. **search_by_release** - 按发布 ID 搜索
9. **search_by_category** - 按分类 ID 搜索


```python
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
```

```python
"""Client (Claude/IDE)
    ↓ stdio (JSON-RPC)
MCP Server
    ↓ 调用
Tools/Resources/Prompts
    ↓ 返回
Client
"""
"""from mcp.types import (
    Tool,           # 工具定义
    Resource,       # 资源定义
    Prompt,         # 提示词定义
    TextContent,    # 文本内容
    ImageContent,   # 图片内容
    EmbeddedResource # 嵌入资源
)
"""
```

## 6. 测试服务器


```python
# 设置 API Key
import os
os.environ['FRED_API_KEY'] = 'b775749de5b0eee7822d31a574da4074'
```

```python
```

```python
# 测试所有工具
!uv run test_all_tools.py
```

## 8. 配置 Claude Desktop

编辑 `~/.config/Claude/claude_desktop_config.json`：

```json
{
  "mcpServers": {
    "fred-api": {
      "command": "uv",
      "args": [
        "--directory",
        "/data/.manjaro/mcp/fredapi-mcp",
        "run",
        "fred_server.py"
      ],
      "env": {
        "FRED_API_KEY": "b775749de5b0eee7822d31a574da4074"
      }
    }
  }
}
```


## 9. 常用数据序列

- `GDP` - 国内生产总值
- `UNRATE` - 失业率
- `CPIAUCSL` - 消费者价格指数
- `FEDFUNDS` - 联邦基金利率
- `M2SL` - M2 货币供应量
- `DGS10` - 10年期国债收益率
- `DEXCHUS` - 美元/人民币汇率


## 10. 相关资源

- FRED API 文档: https://fred.stlouisfed.org/docs/api/
- MCP 文档: https://modelcontextprotocol.io/
- 获取 API Key: https://fred.stlouisfed.org/docs/api/api_key.html

