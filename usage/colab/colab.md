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
echo "done, ip: $(tailscale ip -4)"
```

## 安装 opencode

```bash
[ -x ~/.opencode/bin/opencode ] || curl -fsSL https://opencode.ai/install | bash &> /dev/null
~/.opencode/bin/opencode -v
```

## 上传 AGENTS.md

```bash
colab upload /data/.manjaro/AGENTS.md /root/AGENTS.md
colab ls -s "$mysession" /root | grep AGENTS.md
colab status
```

## 连接

```bash
colab_ip=$(colab exec -s "$mysession" <<< $'%%bash\ntailscale ip -4' 2>/dev/null \
  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
ssh -o StrictHostKeyChecking=accept-new root@"$colab_ip"
```

## 启动 opencode

```bash
~/.opencode/bin/opencode
```

## 停止

```bash
colab stop -s "$mysession"
```
