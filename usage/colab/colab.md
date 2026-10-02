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

## 配置tailscale

### 安装&启动&认证

```bash
command -v tailscale || curl -fsSL https://tailscale.com/install.sh | sh &> /dev/null
tailscale -V
sudo killall tailscaled || true
nohup sudo tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
TS_AUTHKEY="tskey-auth-kntP2EjRL411CNTRL-GkpejtYkZuK27sersA9wuKB8VrfZeukjD"
sudo tailscale --socket=/run/tailscale/tailscaled.sock up \
    --accept-routes --accept-dns=false \
    --ssh --authkey="${TS_AUTHKEY}"
echo "done, ip:"
echo "$(tailscale ip -4)"
```

### colab 保活

```bash
import time
for i in range(1000):
  print(f"alive {i}", flush=True)
  time.sleep(300)  # 5min一次，别太密，输出太多会卡死浏览器
```

## 连接

```bash
ssh -o StrictHostKeyChecking=accept-new root@100.104.49.32
```

## 上传 AGENTS.md

```bash
scp /data/.manjaro/AGENTS.md  root@100.104.49.32:/root/
```

## 安装 opencode

```bash
[ -x ~/.opencode/bin/opencode ] || curl -fsSL https://opencode.ai/v2/install | bash &> /dev/null
~/.opencode/bin/opencode
```

## 停止

```bash
colab stop -s "$mysession"
colab status
```
