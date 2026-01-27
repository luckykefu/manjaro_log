#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
# >>>>>>>>>>>>>>>[ GitHub API 工具 ]>>>>>>>>>>>>>>>
"""

from github import Github
from pathlib import Path


def create_github_repo(repo_name: str, token: str, private: bool = True, description: str = "") -> bool:
    """创建 GitHub 仓库
    :params:
        :repo_name: 仓库名称
        :token: GitHub Personal Access Token
        :private: 是否私有仓库
        :description: 仓库描述
    :return: 是否成功
    """
    print(f"DEBUG: {repo_name=}, {private=}")
    
    try:
        g = Github(token)
        user = g.get_user()
        repo = user.create_repo(repo_name, private=private, description=description)
        print(f"INFO: 仓库创建成功: {repo.html_url}")
        return True
    except Exception as e:
        print(f"ERROR: 创建失败: {e}")
        return False


def list_repos(token: str):
    """列出所有仓库"""
    try:
        g = Github(token)
        user = g.get_user()
        for repo in user.get_repos():
            print(f"{repo.name}: {repo.html_url}")
    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    # 需要先设置 GitHub Token
    # token = "ghp_xxxxxxxxxxxx"
    # create_github_repo("test_repo", token, private=True)
    pass
