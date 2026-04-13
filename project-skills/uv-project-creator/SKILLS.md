---
name: uv-project-creator
description: 初始化uv项目,在 projectFloder 中创建 projectName 项目
---

# uv-project-creator
## 安装 uv
检查是否安装uv，如果没有安装，则安装uv
## 创建项目
```
如果项目不存在，则创建项目
cd <projectFloder> 
uv init <projectName>
# 创建虚拟环境并添加基本包
uv venv 
uv add ipykernel pytest

```

## 创建 SKILLS.md 文件
位置:  `<projectName>/SKILLS.md`
内容如下:
```
---
name: <projectName>
description: 
---

# <projectName>

```