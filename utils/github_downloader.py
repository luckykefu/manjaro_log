#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ GitHub 下载解压工具 ]>>>>>>>>>>>>>>>
"""

import requests
import tarfile
import zipfile
import gzip
import shutil
import time
from functools import wraps
from pathlib import Path
try:
    from config import logger
except ImportError:
    from .config import logger


def retry(retries: int = 3, delay: int = 1):
    """重试装饰器"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    logger.warning(f"{func.__name__} 失败 (尝试 {attempt + 1}/{retries}): {e}")
                    if attempt < retries - 1:
                        time.sleep(delay * (2 ** attempt))
                    else:
                        logger.error(f"{func.__name__} 最终失败")
                        raise
        return wrapper
    return decorator


class GitHubDownloader:
    """GitHub 下载器，支持链式调用"""
    
    def __init__(self, repo_url: str, proxy: str | None = None):
        self.repo_url = repo_url.rstrip('/').split('/releases')[0] if '/releases' in repo_url else repo_url.rstrip('/')
        self.proxy = proxy or "socks5h://192.168.0.103:7897"
        self.proxies = {"http": self.proxy, "https": self.proxy}
        self.urls = []
        self.downloaded_files = []
    
    @retry(retries=3)
    def _fetch_release_urls(self, suffixes: list[str], includes: list[str]):
        """获取 release 下载链接"""
        owner, repo = self.repo_url.split('/')[-2:]
        api_url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
        logger.debug(f"{api_url=}")
        
        resp = requests.get(api_url, proxies=self.proxies, timeout=10)
        resp.raise_for_status()
        assets = resp.json().get("assets", [])
        logger.debug(f"总计 {len(assets)} 个 assets")
        
        return [
            asset["browser_download_url"]
            for asset in assets
            if any(asset["name"].endswith(sfx) for sfx in suffixes) 
            and all(inc in asset["name"] for inc in includes)
        ]
        
    def get_urls(self, suffix: str | list[str], include: str | list[str] | None = None):
        """获取下载链接"""
        suffixes = [suffix] if isinstance(suffix, str) else suffix
        includes = [include] if isinstance(include, str) else (include or [])
        logger.debug(f"{suffixes=}, {includes=}")
        
        try:
            self.urls = self._fetch_release_urls(suffixes, includes)
            logger.info(f"获取到 {len(self.urls)} 个下载链接")
            for url in self.urls:
                logger.debug(f"URL: {url}")
        except Exception:
            pass
        
        return self
    
    @retry(retries=3)
    def _download_file(self, url: str, filename: Path, temp_file: Path):
        """下载单个文件"""
        downloaded_size = temp_file.stat().st_size if temp_file.exists() else 0
        headers = {'Range': f'bytes={downloaded_size}-'} if downloaded_size > 0 else {}
        
        logger.debug(f"开始下载: {url}")
        if downloaded_size > 0:
            logger.info(f"断点续传: {filename.name}, 已下载: {downloaded_size} bytes")
        
        resp = requests.get(url, headers=headers, proxies=self.proxies, stream=True, timeout=30)
        logger.debug(f"HTTP 状态码: {resp.status_code}")
        
        if downloaded_size > 0 and resp.status_code != 206:
            logger.warning("不支持断点续传，重新下载")
            downloaded_size = 0
            temp_file.unlink(missing_ok=True)
            resp = requests.get(url, proxies=self.proxies, stream=True, timeout=30)
        
        resp.raise_for_status()
        total_size = int(resp.headers.get('content-length', 0)) + downloaded_size
        logger.debug(f"文件总大小: {total_size} bytes")
        
        mode = 'ab' if downloaded_size > 0 else 'wb'
        with open(temp_file, mode) as f:
            for chunk in resp.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        
        temp_file.rename(filename)
        logger.info(f"下载成功: {filename.name}")
    
    def download(self, output_dir: str = "~/Downloads"):
        """下载文件，支持断点续传"""
        if not self.urls:
            logger.error("没有可下载的链接")
            return self
        
        output_dir = Path(output_dir).expanduser()
        output_dir.mkdir(parents=True, exist_ok=True)
        logger.debug(f"下载目录: {output_dir}")
        
        for url in self.urls:
            filename = output_dir / url.split('/')[-1]
            temp_file = filename.with_suffix(filename.suffix + '.tmp')
            logger.debug(f"{filename=}, {temp_file=}")
            
            if filename.exists():
                logger.info(f"文件已存在，跳过: {filename.name}")
                self.downloaded_files.append(filename)
                continue
            
            try:
                self._download_file(url, filename, temp_file)
                self.downloaded_files.append(filename)
            except Exception as e:
                logger.error(f"下载异常: {e}")
        
        return self
    
    def extract(self, output_dir: str | None = None):
        """解压下载的文件"""
        if not self.downloaded_files:
            logger.error("没有可解压的文件")
            return self
        
        for file_path in self.downloaded_files:
            extract_dir = Path(output_dir).expanduser() if output_dir else file_path.parent
            extract_dir.mkdir(parents=True, exist_ok=True)
            logger.debug(f"解压: {file_path} -> {extract_dir}")
            
            try:
                if file_path.suffix in ['.gz', '.bz2', '.xz', '.zst'] or '.tar' in file_path.name:
                    with tarfile.open(file_path, 'r:*') as tar:
                        tar.extractall(extract_dir)
                        logger.info(f"解压成功: {file_path.name} -> {extract_dir}")
                
                elif file_path.suffix == '.zip':
                    with zipfile.ZipFile(file_path, 'r') as zip_ref:
                        zip_ref.extractall(extract_dir)
                        logger.info(f"解压成功: {file_path.name} -> {extract_dir}")
                
                elif file_path.suffix == '.gz' and '.tar' not in file_path.name:
                    output_file = extract_dir / file_path.stem
                    with gzip.open(file_path, 'rb') as f_in:
                        with open(output_file, 'wb') as f_out:
                            shutil.copyfileobj(f_in, f_out)
                    logger.info(f"解压成功: {file_path.name} -> {output_file}")
                
                else:
                    logger.warning(f"不支持的压缩格式: {file_path.suffix}")
                    
            except Exception as e:
                logger.error(f"解压失败: {file_path}, {e}")
        
        return self


if __name__ == "__main__":
    # 链式调用示例
    GitHubDownloader("https://github.com/ollama/ollama") \
        .get_urls(suffix=".tar.zst", include=["linux", "amd64"]) \
        .download(output_dir="~/Downloads") \
        .extract(output_dir="/data/.path/.ollama")
