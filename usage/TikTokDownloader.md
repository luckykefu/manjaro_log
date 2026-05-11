## conda env


```bash
%%bash
conda env list | grep "^TikTokDownloader" || conda create -n TikTokDownloader python=3.12 ipykernel -y
```

```python
%cd /data/projects

!git clone https://github.com/JoeanAmier/TikTokDownloader.git 
```

```python
%cd TikTokDownloader

%pip install -r requirements.txt
```

```python
!python main.py
```

## get cookies


```python
# 这个项目是如何获取cookies的
# 使用 rookiepy 库读取浏览器 Cookie 数据库
from rookiepy import chrome

# 读取浏览器 Cookie 数据库
cookies = chrome(domains=["douyin.com"])

# 转换为字典
cookie_dict = {i["name"]: i["value"] for i in cookies}
```
