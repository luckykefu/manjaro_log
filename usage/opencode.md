# OpenCode 使用教程

## 安装

```bash
npm install -g @openai/codex
# 或
brew install --cask codex
```

## 常用命令

- `codex` - 启动 CLI
- `codex app` - 启动桌面应用
- `/connect` - 连接 Provider
- `/models` - 查看可用模型
- `/help` - 获取帮助

## NVIDIA-NIM

### 获取 API Key

1. 访问 https://build.nvidia.com
2. 注册账号并生成 API Key
3. 新用户获得 1,000 免费推理积分

### 配置文件

```json
// ~/.config/opencode/opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "nvidia": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://integrate.api.nvidia.com/v1",
        "headers": {
          "Authorization": "Bearer nvapi-your-api-key-here"
        }
      },
      "models": {
        "deepseek-ai/deepseek-v4-pro": {
          "name": "deepseek-v4-pro"
        },
        "deepseek-ai/deepseek-v4-flash": {
          "name": "deepseek-v4-flash"
        },
        "z-ai/glm-5.1": {
          "name": "GLM-5.1"
        }
      }
    }
  }
}
```

### 连接 Provider

1. 运行 `codex`
2. 执行 `/connect`
3. 选择 `nvidia` provider
4. 输入 API Key

### 验证 API

```bash
curl -s -H "Authorization: Bearer nvapi-your-api-key-here" \
  https://integrate.api.nvidia.com/v1/models | jq '.data[0].id'
```

## 其他 Provider

配置方式类似，参考 OpenRouter 使用。