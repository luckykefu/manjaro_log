## 内存不足


```python
conda create -n heartlib python=3.10 ipykernel -y
```

```bash
%%bash
cd /data/projects
export all_proxy="socks5://192.168.0.103:7897"
git clone https://github.com/HeartMuLa/heartlib.git
```

```python
%cd /data/projects/heartlib
%pip install -e .
```

```python
%pip uninstall torch torchvision torchaudio -y
%pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.4
```

```python
import torch
print(f"{torch.__version__=}")
print(f"{torch.cuda.is_available()=}")
print(f"{torch.cuda.get_device_name(0)=}" if torch.cuda.is_available() else "No GPU")
```

```bash
%%bash
cd /data/projects/heartlib
modelscope download --model 'HeartMuLa/HeartMuLaGen' --local_dir './ckpt'
modelscope download --model 'HeartMuLa/HeartMuLa-oss-3B' --local_dir './ckpt/HeartMuLa-oss-3B'
modelscope download --model 'HeartMuLa/HeartCodec-oss' --local_dir './ckpt/HeartCodec-oss'
```

```python
import torch
torch.cuda.empty_cache()
```

```bash
%%bash
cd /data/projects/heartlib
HSA_OVERRIDE_GFX_VERSION=10.3.0 python ./examples/run_music_generation.py --model_path=./ckpt  --lazy_load true --version="3B"
```
