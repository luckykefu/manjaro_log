#!/usr/bin/env bash
set -euo pipefail

add_zshrc_config() {
    local zshrc="${HOME}/.zshrc"
    [[ ! -f "${zshrc}" ]] && touch "${zshrc}"
    
    local added=0
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        grep -Fxq "${line}" "${zshrc}" && continue
        echo "${line}" >> "${zshrc}"
        ((added++))
    done <<'EOF'
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
export UV_CACHE_DIR="/data/.uv-cache"
export PATH="$PATH:/data/.path/.appimage"
export HTTPS_PROXY="socks5h://192.168.0.103:7897"
export HTTP_PROXY="socks5h://192.168.0.103:7897"
export PATH="$PATH:/data/.path/.ollama/bin"
export HSA_OVERRIDE_GFX_VERSION=10.3.0

export FREQTRADE__EXCHANGE__KEY=f440ea078e7646f0e62ade6c47b7710b
export FREQTRADE__EXCHANGE__SECRET=f0dd66351842c0d487b92936018e3312f01bd68ccc525b3fd61f42343d0a208a
export FREQTRADE__TELEGRAM__TOKEN=8283811781:AAHqaD7lAZEU8kHWjknfMna8bXH7Gin1fjQ
export FREQTRADE__TELEGRAM__CHAT_ID=700812817

source /data/.zshplugins/zsh-sudo/zsh-sudo.zsh
source $HOME/.cargo/env
EOF
    
    [[ ${added} -gt 0 ]] && echo "已添加 ${added} 行配置到 ${zshrc}" || echo "所有配置已存在"
}

add_zshrc_config
