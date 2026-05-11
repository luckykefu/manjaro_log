#!/bin/sh

app-update() {
    repo="$1"
    bin_dir="${2:-/run/media/manjaro/data/.apps/bin}"

    if [ -z "$repo" ] || [ -z "$bin_dir" ]; then
        echo "用法: app-update <user/repo> <bin_dir>"
        return 1
    fi

    bin_name="${repo##*/}"
    app_dir="$(dirname "$bin_dir")/$bin_name"

    url=$(
        curl -sL "https://api.github.com/repos/$repo/releases/latest" | \
            jq -r '.assets[] | select(.name | endswith(".tar.gz") and contains("x86_64") and contains("linux")) | .browser_download_url' | head -1
    )

    if [ -z "$url" ]; then
        echo "未找到 linux x86_64 tar.gz"
        return 1
    fi

    echo "下载: $url"
    mkdir -p "$app_dir"

    (
        curl -sL "$url" | tar xz -C "$app_dir" --strip-components=1
    )

    bin_file=$(find "$app_dir" -type f -executable | head -1)
    if [ -z "$bin_file" ]; then
        echo "未找到可执行文件"
        return 1
    fi

    ln -s "$bin_file" "$bin_dir/$bin_name"
    echo "已更新: $("$bin_dir/$bin_name" --version 2>/dev/null || echo ok)"
}
app-update "$@"
