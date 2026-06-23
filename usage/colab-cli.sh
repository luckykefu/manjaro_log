# # Colab CLI 使用指南

# 流程:

# 1. 安装
# 2. 认证
# 3. 创建项目
# 4. 创建会话
# 5. 配置tailscale: 安装,启动,认证
# 6. 配置ssh:
# 7. 连接
# 8. 释放会话

# ## 安装
install(){
    sudo pacman -S --needed --noconfirm google-cloud-cli uv
    uv tool install google-colab-cli
}
install

gcloud auth login

gcloud projects create nutilustrader --name="Nutilustrader"
gcloud config set project nutilustrader
gcloud auth application-default set-quota-project nutilustrader
gcloud services enable storage.googleapis.com --project nutilustrader

mysession=colab-mysession
colab new -s "$mysession"

colab exec -s "$mysession" -f usage/tailscale.sh
colab exec -s "$mysession" <<'EOF'
%%bash
[ -x ~/.opencode/bin/opencode ] || curl -fsSL https://opencode.ai/install | bash &> /dev/null
~/.opencode/bin/opencode -v
EOF
colab upload AGENTS.md /root/AGENTS.md
colab ls -s "$mysession" /root

colab_ip=$(colab exec -s "$mysession" <<< $'%%bash\ntailscale ip -4' 2>/dev/null \
  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
ssh root@"$colab_ip"
# ~/.opencode/bin/opencode

colab stop -s "$mysession"


colab status
colab console -s "$mysession"      # 远程 shell（注意：有卡死 bug，不推荐）

# 一键执行（创建 → 运行 → 释放）
colab run --gpu T4 train.py
