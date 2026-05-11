## 配置


### amd gpu


```python
!sudo pacman -S --needed --noconfirm rocm-opencl-runtime rocm-hip-runtime
```

```python
# 添加..utils到sys.path
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname("__file__"), '..', 'utils')))
```

### install


```python
# 下载文件到~/.Downloads
# https://github.com/ollama/ollama
```

```python
!rm -fr /data/.path/.ollama
```

```python
mkdir -p /data/.path/.ollama && for f in ~/Downloads/*.tar.zst; do tar -xvf "$f" -C /data/.path/.ollama; done
```

```python
!DIR="/data/.path/.ollama/bin" && grep -qxF "export PATH=\"\$PATH:$DIR\"" ~/.zshrc || echo "export PATH=\"\$PATH:$DIR\"" >> ~/.zshrc
!grep -qxF 'export HSA_OVERRIDE_GFX_VERSION=10.3.0' ~/.zshrc || echo 'export HSA_OVERRIDE_GFX_VERSION=10.3.0' >> ~/.zshrc
!tail -n 5 ~/.zshrc
```

```python
!mkdir -p /data/.home/.ollama && ln -sfn /data/.home/.ollama ~/.ollama
```

### start serve


```python
## run
!grep -qxF 'export HSA_OVERRIDE_GFX_VERSION=10.3.0' ~/.zshrc || echo 'export HSA_OVERRIDE_GFX_VERSION=10.3.0' >> ~/.zshrc
!tail -n 5 ~/.zshrc

# HSA_OVERRIDE_GFX_VERSION=10.3.0 ollama serve
```

### pull model


```python
# https://ollama.com/search
!ollama pull gemma4
```

# MCP

```python
%cd /data/projects_ING
```

## ollama-mcp-bridge

```python
![ ! -d ollama-mcp-bridge ] && git clone https://github.com/patruff/ollama-mcp-bridge.git || echo 'already exists'
```

## mcp tools

```python
!sudo npm install -g @modelcontextprotocol/server-filesystem
```

```python
/data/projects_ING/ollama-mcp-bridge/bridge_config.json
```

## ollama python 

```python
!uv init ollama-python
```

```python
%cd ollama-python
```

```python
!uv venv
```

```python
!uv add ollama mcp
```

```python
# 检查ollama serve是否启动
!ls
```
