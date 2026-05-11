#!/usr/bin/env bash
set -euo pipefail
repo_url="$1"
file_type="$2"
bin_dir="${3:-.bin}"
cd "$(dirname "$0")"
mkdir -p "$bin_dir"
owner="$(echo "$repo_url" | sed -E 's|https?://github\.com/||; s|/.*||')"
bin_name="$(echo "$repo_url" | sed -E 's|\.git$||; s|.*/||')"
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
release_info="$(curl -sfL "https://api.github.com/repos/${owner}/${bin_name}/releases/latest")"
asset_name="$(echo "$release_info" | jq -r ".assets[] | select($jq_select) | .name" | head -1)"
download_url="$(echo "$release_info" | jq -r ".assets[] | select($jq_select) | .browser_download_url" | head -1)"
if [[ -z "$asset_name" ]]; then
    echo "No matching asset found for type: $file_type" >&2
    exit 1
fi

rm -fr "${bin_dir:?}/${bin_name:?}"
tmp_dir="$(mktemp -d)"
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
