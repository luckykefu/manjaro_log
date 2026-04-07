#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# [ GitHub Release 下载工具 ]
"""

import shutil
import subprocess
import tarfile
import zipfile
from pathlib import Path

import httpx
from config import logger


class GitHubDownloader:
    """
    GitHub Release 下载器（链式调用）
    :params:
        :repo_url: GitHub 仓库地址，如 https://github.com/owner/repo
    """

    API = "https://api.github.com/repos/{owner}/{repo}/releases/latest"
    PROXY = "socks5://192.168.0.103:7897"

    def __init__(self, repo_url: str) -> None:
        # [ 参数验证 ]
        logger.debug(f"{repo_url=}")
        parts = repo_url.rstrip("/").split("/")
        self._owner, self._repo = parts[-2], parts[-1]
        self._urls: list[str] = []
        self._downloaded: list[Path] = []

    # [ 获取下载链接 ]
    def get_urls(self, suffix: str = "", include: list[str] | None = None) -> "GitHubDownloader":
        """
        获取 Release 资产下载链接
        :params:
            :suffix:  文件后缀过滤，如 .tar.gz
            :include: 文件名必须包含的关键词列表，如 ["linux", "amd64"]
        """
        url = self.API.format(owner=self._owner, repo=self._repo)
        logger.debug(f"{url=}")
        try:
            resp = httpx.get(url, proxy=self.PROXY, timeout=15, follow_redirects=True)
            resp.raise_for_status()
            assets: list[dict] = resp.json().get("assets", [])
            self._urls = [
                a["browser_download_url"]
                for a in assets
                if a["name"].endswith(suffix)
                and all(kw in a["name"] for kw in (include or []))
            ]
            logger.info(f"{self._urls=}")
        except Exception as e:
            logger.error(f"{e=}")
        return self

    # [ 下载文件 ]
    def download(self, output_dir: str = "~/Downloads") -> "GitHubDownloader":
        """
        下载所有匹配文件
        :params:
            :output_dir: 下载目录
        """
        dest = Path(output_dir).expanduser()
        dest.mkdir(parents=True, exist_ok=True)
        logger.debug(f"{dest=}")

        for url in self._urls:
            filename = url.split("/")[-1]
            filepath = dest / filename
            try:
                with httpx.stream("GET", url, proxy=self.PROXY, timeout=60, follow_redirects=True) as r:
                    r.raise_for_status()
                    with open(filepath, "wb") as f:
                        for chunk in r.iter_bytes(chunk_size=8192):
                            f.write(chunk)
                self._downloaded.append(filepath)
                logger.info(f"下载完成: {filepath=}")
            except Exception as e:
                logger.error(f"{url=}, {e=}")
        return self

    # [ 解压文件 ]
    def extract(self, output_dir: str = ".") -> "GitHubDownloader":
        """
        解压所有已下载文件
        :params:
            :output_dir: 解压目标目录
        """
        dest = Path(output_dir).expanduser()
        dest.mkdir(parents=True, exist_ok=True)
        logger.debug(f"{dest=}")

        for filepath in self._downloaded:
            try:
                if filepath.suffix == ".zst" and ".tar" in filepath.name:
                    if not shutil.which("tar"):
                        raise RuntimeError("tar 未安装")
                    subprocess.run(
                        ["tar", "--zstd", "-xf", str(filepath), "-C", str(dest)],
                        check=True
                    )
                elif tarfile.is_tarfile(filepath):
                    with tarfile.open(filepath) as tf:
                        tf.extractall(dest)
                elif zipfile.is_zipfile(filepath):
                    with zipfile.ZipFile(filepath) as zf:
                        zf.extractall(dest)
                else:
                    logger.error(f"不支持的格式: {filepath=}")
                    continue
                logger.info(f"解压完成: {filepath.name} → {dest}")
            except Exception as e:
                logger.error(f"{filepath=}, {e=}")
        return self


if __name__ == "__main__":
    # [ 使用示例 ]
    GitHubDownloader("https://github.com/ollama/ollama") \
        .get_urls(suffix=".tar.zst", include=["linux", "amd64"]) \
        .download(output_dir="~/Downloads") \
        .extract(output_dir="/data/.path/.ollama")
