# Colab CLI 使用指南

## 安装 gcloud & colab

```bash
sudo pacman -S --needed --noconfirm google-cloud-cli uv
uv tool install google-colab-cli
```

## 认证

```bash
gcloud auth login
```

## 创建项目

```bash
gcloud projects list
gcloud projects create nutilustrader --name="Nutilustrader"
gcloud config set project nutilustrader
gcloud auth application-default set-quota-project nutilustrader
gcloud services enable storage.googleapis.com --project nutilustrader
```

## 创建会话

```bash
mysession=colab-mysession
colab new -s "$mysession"
```

## colab 终端

```bash
colab console -s "$mysession"
```

## [配置tailscale](./配置tailscale.sh)

### colab 保活

```bash
import time
for i in range(1000):
  print(f"alive {i}", flush=True)
  time.sleep(600)  # 5min一次，别太密，输出太多会卡死浏览器
```

## 连接 colab

```bash
ssh -o StrictHostKeyChecking=accept-new root@100.104.49.32
```

## 停止

```bash
colab stop -s "$mysession"
colab status
```
