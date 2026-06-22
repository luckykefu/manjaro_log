# Colab CLI 使用指南

## 安装

```bash
sudo pacman -S --needed --noconfirm google-cloud-cli
uv tool install google-colab-cli
```

## 认证

```bash
gcloud auth  login 
```

## 实例管理

```bash
# colab new                       # 默认 CPU 实例
gcloud auth login
gcloud projects list 
gcloud projects create nutilustrader --name="Nutilustrader"
# gcloud services enable storage.googleapis.com --project nutilustrader 
gcloud config set project nutilustrader 
 gcloud auth application-default set-quota-project nutilustrader

colab sessions                  # 列出所有实例
mysession=$(colab sessions | head -1 | sed -n 's/^\[\(.*\)\].*/\1/p')
colab stop -s "$mysession"  

colab new -s "$mysession"          # 指定会话名
colab new --gpu T4              # GPU 实例
colab new --gpu A100            # A100 实例（需配额）
colab new --gpu H100            # H100 实例（Pro+）

colab status -s "$mysession"       # 查看实例详情
```

## 执行代码

```bash
colab exec -f train.py          # 运行本地脚本
colab exec <<< 'print("hi")'    # 标准输入
colab repl -s "$mysession"         # 交互式 Python
colab console -s "$mysession"      # 远程 shell

# 一键执行（创建 → 运行 → 释放）
colab run --gpu T4 train.py
```

## 文件操作

```bash
colab upload AGENTS.md /content/AGENTS.md
colab download /content/remote.txt ./
colab ls -s "$mysession" /content/
colab rm -s "$mysession" /content/tmp
colab edit -s "$mysession" script.py
```

## 环境配置

```bash
colab install torch             # 安装包
colab install -r requirements.txt
colab drivemount                # 挂载 Google Drive
colab auth                      # GCP 认证
colab log -o notebook.ipynb     # 导出日志
```

## 注意事项

- 免费版最长 12h，Pro 24h，Pro+ 36h
- CLI 自动启动 keep-alive 守护进程（每 60s ping）
- `colab stop` 后停止消耗计算单元
- 不指定 `-s` 时使用默认匿名会话
