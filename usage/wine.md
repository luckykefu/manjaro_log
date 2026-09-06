```bash
sudo pacman -S --noconfirm --needed wine wine-mono wine-gecko winetricks 
```

#### aliyunpan


```bash
%%bash
f=$(find $(pwd) -name "install_and_start_wine.sh" -type f)
echo "$f"
source "$f"
## install_to_wine aliyunpan
## ## run in terminal
#start_wine_exe aliyunpan "/home/lkf/.wine/aliyunpan/drive_c/users/lkf/AppData/Local/Programs/aDrive/aDrive.exe"
```

#### xstudio


```bash
%%bash
f=$(find $(pwd) -name "install_and_start_wine.sh" -type f)
echo "$f"
source "$f"
install_to_wine XStudio

## ## run in terminal
## install_and_start_wine.sh --start XStudio "/data/.wine/XStudio/drive_c/Program Files/NetEase Cloud Music XStudio/NetEase Cloud Music XStudio.exe"
```

#### 三国谋定天下


```bash
w=/data/.wine/sgmdtx
exe=$HOME/Downloads/NSLG_Setup_202607131602.exe
WINEPREFIX=$w winetricks cjkfonts vcrun2019
WINEPREFIX=$w wine $exe

WINEPREFIX=$w wine "/data/.wine/sgmdtx/drive_c/Program Files/bilibili Game/NSLG/NSLG.exe"
```

#### 微信


```bash
%%bash
f=$(find $(pwd) -name "install_and_start_wine.sh" -type f)
echo "$f"
source "$f"
install_to_wine wechat vcrun2019 cjkfonts

## ## run in terminal
## install_and_start_wine.sh --start wechat "/data/.wine/wechat/drive_c/Program Files/Tencent/Weixin/Weixin.exe"
```

## 安装 yabridge


```bash
%%bash
echo "Installing yabridge..."
sudo pacman -S --noconfirm --needed yabridgectl >/dev/null
```
