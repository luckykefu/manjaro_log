## 安装&配置

```bash
%%bash
#!/usr/bin/env bash
set -e

# 安装 uv
echo "安装 uv..."
sudo pacman -S --needed --noconfirm uv 

# 配置环境变量
ZSHRC="${HOME}/.zshrc"

echo "配置环境变量..."

# 检查并添加 UV_DEFAULT_INDEX
if ! grep -q "export UV_DEFAULT_INDEX=" "${ZSHRC}"; then
    echo 'export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"' >> "${ZSHRC}"
    echo "✓ 已添加 UV_DEFAULT_INDEX"
else
    echo "✓ UV_DEFAULT_INDEX 已存在"
fi

# 检查并添加 UV_CACHE_DIR
if ! grep -q "export UV_CACHE_DIR=" "${ZSHRC}"; then
    echo 'export UV_CACHE_DIR="/data/.uv-cache"' >> "${ZSHRC}"
    echo "✓ 已添加 UV_CACHE_DIR"
else
    echo "✓ UV_CACHE_DIR 已存在"
fi

# 创建缓存目录
mkdir -p /data/.uv-cache

# 安装全局工具
echo "安装全局工具..."
uv tool install ruff

echo ""
echo "✅ 安装完成！"
echo "请运行: source ~/.zshrc"
```

## 3. 项目管理


```python
uv init
uv venv
uv add ipykernel pytest
```
