# 自建 VPS 教程

>登陆web:  https://my.vultr.com/
>选择 Cloud Compute,创建vps


## 服务器配置


```bash
%%bash
bash /data/.manjaro/utils/ss_deploy.sh
```

## 本地配置


### ssh


```python
# ssh -D 1080 -N -f -C root@202.182.112.91
```

### clash


```python
!uv run python ../utils/clash.py 202.182.112.91
```

### shadowsocks

```python
!bash ../utils/ss_local.sh 202.182.112.91 
```
