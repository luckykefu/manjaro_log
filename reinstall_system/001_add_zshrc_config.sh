#!/usr/bin/env bash
set -euo pipefail

add_zshrc_config() {
    # 向 ~/.zshrc 追加环境配置，已存在的行跳过（幂等）
    local zshrc="${HOME}/.zshrc"
    [[ ! -f "${zshrc}" ]] && touch "${zshrc}"  # zshrc 不存在则创建
    
    local added=0
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue          # 跳过空行
        grep -Fxq "${line}" "${zshrc}" && continue  # 已存在则跳过
        echo "${line}" >> "${zshrc}"            # 追加新行
        ((added++)) || true
    done <<'EOF'
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
export UV_CACHE_DIR="/data/.uv-cache"
export UV_LINK_MODE=copy
export PATH="$PATH:/data/.path/.appimage"
export https_proxy=socks5h://127.0.0.1:7897 http_proxy=socks5h://127.0.0.1:7897
export PATH="$PATH:/data/.path/.ollama/bin"
export HSA_OVERRIDE_GFX_VERSION=10.3.0
source /data/.zshplugins/zsh-sudo/zsh-sudo.zsh
EOF
    
    [[ ${added} -gt 0 ]] && echo "已添加 ${added} 行配置到 ${zshrc}" || echo "所有配置已存在"
}

add_zshrc_config