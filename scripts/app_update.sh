#!/usr/bin/env bash

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "${COMMON_DIR}/common.sh"

app_update() {
    ensure_cmd curl
    local repo_url="$1"
    local file_type="$2"
    local bin_dir="${3:-.bin}"

    cd "$(dirname "${BASH_SOURCE[0]}")"
    mkdir -p "$bin_dir"

    local owner bin_name
    owner=$(echo "$repo_url" | sed -E 's|https?://github\.com/||; s|/.*||')
    bin_name=$(echo "$repo_url" | sed -E 's|\.git$||; s|.*/||')

    local jq_select
    case "$file_type" in
        AppImage) jq_select='.name | endswith(".AppImage") and contains("x86_64")' ;;
        tar.gz|tgz) jq_select='.name | endswith(".tar.gz") and contains("x86_64") and contains("linux")' ;;
    esac
    ensure_cmd jq
    ensure_cmd tar

    local release_info asset_name download_url tmp_dir
    release_info=$(curl -sfL "https://api.github.com/repos/${owner}/${bin_name}/releases/latest")
    asset_name=$(echo "$release_info" | jq -r ".assets[] | select($jq_select) | .name" | head -1)
    download_url=$(echo "$release_info" | jq -r ".assets[] | select($jq_select) | .browser_download_url" | head -1)

    rm_or_skip "${bin_dir:?}/${bin_name:?}" delete
    tmp_dir=$(mktemp -d)
    trap 'rm -fr "$tmp_dir"' EXIT
    curl -#L "$download_url" -o "${tmp_dir}/${asset_name}"

    case "$file_type" in
        AppImage)
            cp "${tmp_dir}/${asset_name}" "${bin_dir}/${bin_name}"
            chmod +x "${bin_dir}/${bin_name}" ;;
        tar.gz|tgz)
            tar -xzf "${tmp_dir}/${asset_name}" -C "$bin_dir" ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && app_update "$@"