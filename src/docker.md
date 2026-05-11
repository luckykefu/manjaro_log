```bash
%%bash
echo "Installing docker..."
sudo pacman -S --noconfirm --needed docker >/dev/null
```

### 配置 Docker


```bash
%%bash
daemon_file="/etc/docker/daemon.json"

sudo systemctl stop docker &>/dev/null

sudo mkdir -p /etc/docker
sudo tee "$daemon_file" > /dev/null <<'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.1panel.live",
    "https://docker.m.ixdev.cn",
    "https://hub.rat.dev",
    "https://dockerproxy.net",
    "https://docker.hlmirror.com",
    "https://hub1.nat.tf",
    "https://hub3.nat.tf",
    "https://docker.m.daocloud.io",
    "https://docker.kejilion.pro",
    "https://hub.1panel.dev",
    "https://dockerproxy.cool",
    "https://proxy.vvvv.ee"
  ]
}
EOF

sudo usermod -aG docker "$USER" &>/dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now docker &>/dev/null

echo "✓ Docker configured"
echo "⚠ Please logout and login again for group changes to take effect"
```

# Docker 应用创建教程


## 1. Docker 基础概念

- **镜像(Image)**: 应用的只读模板
- **容器(Container)**: 镜像的运行实例
- **Dockerfile**: 构建镜像的脚本
- **仓库(Registry)**: 存储镜像的地方(如 Docker Hub)


## 2. 创建简单 Python Web 应用


```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>步骤1: 创建项目目录>>>>>>>>>>>>>>>>
mkdir -p docker_demo
cd docker_demo
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>步骤2: 创建应用代码>>>>>>>>>>>>>>>>
cat > docker_demo/app.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# >>>>>>>>>>>>>>>简单的 Flask Web 应用>>>>>>>>>>>>>>>>

from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello from Docker!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
EOF
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>步骤3: 创建依赖文件>>>>>>>>>>>>>>>>
cat > docker_demo/requirements.txt << 'EOF'
flask==3.0.0
EOF
```

## 3. 编写 Dockerfile


```bash
%%bash
cat > docker_demo/Dockerfile << 'EOF'
# >>>>>>>>>>>>>>>>>>>>基础镜像>>>>>>>>>>>>>>>>
FROM python:3.11-slim

# >>>>>>>>>>>>>>>>>>>>设置工作目录>>>>>>>>>>>>>>>>
WORKDIR /app

# >>>>>>>>>>>>>>>>>>>>复制依赖文件>>>>>>>>>>>>>>>>
COPY requirements.txt .

# >>>>>>>>>>>>>>>>>>>>安装依赖>>>>>>>>>>>>>>>>
RUN pip install --no-cache-dir -r requirements.txt

# >>>>>>>>>>>>>>>>>>>>复制应用代码>>>>>>>>>>>>>>>>
COPY app.py .

# >>>>>>>>>>>>>>>>>>>>暴露端口>>>>>>>>>>>>>>>>
EXPOSE 5000

# >>>>>>>>>>>>>>>>>>>>启动命令>>>>>>>>>>>>>>>>
CMD ["python", "app.py"]
EOF
```

## 4. 构建镜像


```bash
%%bash
cd docker_demo
docker build -t my-flask-app:latest .
```

## 5. 运行容器


```bash
%%bash
docker run -d  \
  --name flask-demo \
  -p 5001:5000 \
  my-flask-app:latest
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>测试应用>>>>>>>>>>>>>>>>
curl http://localhost:5001
```

## 6. 带数据持久化的应用


```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>使用卷挂载>>>>>>>>>>>>>>>>
docker run -d \
  --name app-with-data \
  -p 8080:5000 \
  -v /data/.docker/app-data:/app/data \
  my-flask-app:latest
```

## 7. 常用 Docker 命令


```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>查看运行中的容器>>>>>>>>>>>>>>>>
docker ps
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>查看所有容器>>>>>>>>>>>>>>>>
docker ps -a
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>查看容器日志>>>>>>>>>>>>>>>>
docker logs flask-demo
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>停止容器>>>>>>>>>>>>>>>>
docker stop flask-demo
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>启动容器>>>>>>>>>>>>>>>>
docker start flask-demo
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>删除容器>>>>>>>>>>>>>>>>
docker rm flask-demo
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>查看镜像>>>>>>>>>>>>>>>>
docker images
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>删除镜像>>>>>>>>>>>>>>>>
docker rmi my-flask-app:latest
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>进入容器>>>>>>>>>>>>>>>>
docker exec -it flask-demo /bin/bash
```

## 8. Docker Compose 示例


```bash
%%bash
cat > docker_demo/docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - /data/.docker/app-data:/app/data
    restart: unless-stopped
EOF
```

```bash
%%bash
cd docker_demo
# >>>>>>>>>>>>>>>>>>>>启动服务>>>>>>>>>>>>>>>>
docker-compose up -d
```

```bash
%%bash
cd docker_demo
# >>>>>>>>>>>>>>>>>>>>停止服务>>>>>>>>>>>>>>>>
docker-compose down
```

## 9. 实际应用示例


```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>Memos 笔记应用>>>>>>>>>>>>>>>>
docker run -d \
  --name memos \
  -p 5230:5230 \
  -v /data/.home/.memos:/var/opt/memos \
  neosmemo/memos:stable
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>Nginx Web 服务器>>>>>>>>>>>>>>>>
docker run -d \
  --name nginx \
  -p 80:80 \
  -v /data/.docker/nginx/html:/usr/share/nginx/html \
  nginx:alpine
```

## 10. 清理资源


```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>清理未使用的容器>>>>>>>>>>>>>>>>
docker container prune -f
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>清理未使用的镜像>>>>>>>>>>>>>>>>
docker image prune -a -f
```

```bash
%%bash
# >>>>>>>>>>>>>>>>>>>>清理所有未使用资源>>>>>>>>>>>>>>>>
docker system prune -a -f --volumes
```
