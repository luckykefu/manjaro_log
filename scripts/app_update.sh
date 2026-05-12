#!/usr/bin/env bash
set -euo pipefail

app_update() {
    local repo_url="$1"
    local file_type="$2"
    local bin_dir="${3:-.bin}"
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"
    mkdir -p "$bin_dir"
    local owner
    owner=$(echo "$repo_url" | sed -E 's|https?://github\.com/||; s|/.*||')
    local bin_name
    bin_name=$(echo "$repo_url" | sed -E 's|\.git$||; s|.*/||')

    local jq_select
    case "$file_type" in
        AppImage)
            jq_select='.name | endswith(".AppImage") and contains("x86_64")'
            ;;
        tar.gz|tgz)
            jq_select='.name | endswith(".tar.gz") and contains("x86_64") and contains("linux")'
            ;;
        *)
            echo "Unsupported file type: $file_type" >&2
            exit 1
            ;;
    esac

    local release_info
    release_info=$(curl -sfL "https://api.github.com/repos/${owner}/${bin_name}/releases/latest")
    local asset_name
    asset_name=$(echo "$release_info" | jq -r ".assets[] | select($jq_select) | .name" | head -1)
    local download_url
    download_url=$(echo "$release_info" | jq -r ".assets[] | select($jq_select) | .browser_download_url" | head -1)

    [[ -z "$asset_name" ]] && { echo "No matching asset found for type: $file_type" >&2; exit 1; }

    rm -fr "${bin_dir:?}/${bin_name:?}"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -fr "$tmp_dir"' EXIT
    curl -#L "$download_url" -o "${tmp_dir}/${asset_name}"

    case "$file_type" in
        AppImage)
            mkdir -p "$bin_dir"
            cp "${tmp_dir}/${asset_name}" "${bin_dir}/${bin_name}"
            chmod +x "${bin_dir}/${bin_name}"
            echo "Installed to ${bin_dir}/${bin_name}"
            ;;
        tar.gz|tgz)
            mkdir -p "$bin_dir"
            tar -xzf "${tmp_dir}/${asset_name}" -C "$bin_dir"
            echo "Extracted to ${bin_dir}"
            ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && app_update "$@"