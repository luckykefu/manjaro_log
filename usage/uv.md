# uv 使用指南

## 安装

```bash
# Manjaro / Arch Linux
sudo pacman -S uv

# pip（需要 Python 3.13+）
pip install uv

# 官方安装脚本
bin=~/.local/bin/uv && [ -x "$bin" ] ||  curl -fsSL https://opencode.ai/install | bash &> /dev/null && "$bin" -V
```

## 国内源

```bash
zsh_path=reinstallOS/src/.zsh/uv.zsh

cat > "$zsh_path" << 'EOF'
# # 清华 TUNA（推荐）
# export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"

# # 阿里云
# export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple"

# 中国科学技术大学
export UV_DEFAULT_INDEX="https://pypi.mirrors.ustc.edu.cn/simple"

# 自定义缓存目录
export UV_CACHE_DIR="/data/.uv-cache"
EOF

```

## 使用示例

### 项目初始化

```bash
uv init my-project
cd my-project
```

### 虚拟环境

```bash
uv venv                  # 创建 .venv
uv venv venv             # 指定目录名
```

### 依赖管理

```bash
uv add requests          # 安装依赖
uv add --dev pytest      # 开发依赖
uv sync                  # 同步 uv.lock
uv lock                  # 更新锁定文件
```

### 运行脚本

```bash
uv run main.py           # 在 venv 中运行
uv run pytest            # 运行测试
uv run --with torch python train.py  # 临时依赖
```

### 全局工具

```bash
uv tool install ruff     # 安装全局工具
uv tool list             # 列出已安装工具
uv tool install uv run   # 用 uv 运行工具
```

### 兼容 pip

```bash
uv pip install -r requirements.txt
uv pip list
uv pip freeze
```
