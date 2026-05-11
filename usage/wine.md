```bash
%%bash
echo "Installing wine..."
sudo pacman -S --noconfirm --needed wine wine-mono wine-gecko winetricks >/dev/null
```

#### StudioOnePro7


```bash
%%bash

w=/data/.home/.wine/StudioOneProv7.2.3
exe=$HOME/Downloads/exe/StudioOneProv7.2.3.exe
WINEPREFIX=/data/.home/.wine/StudioOneProv7.2.3 winetricks cjkfonts
WINEPREFIX=/data/.home/.wine/StudioOneProv7.2.3 wine $HOME/Downloads/exe/StudioOneProv7.2.3.exe
## ## run in terminal
WINEPREFIX=/data/.home/.wine/StudioOneProv7.2.3 wine "/home/lkf/.wine/StudioOneProv7.2.3/drive_c/Program Files/PreSonus/Studio One 7/Studio One.exe"
```

#### jmzy


```bash
%%bash
f=$(find $(pwd) -name "install_and_start_wine.sh" -type f)
echo "$f"
source "$f"
## install_to_wine jmzy
## ## run in terminal
start_wine_exe jmzy "/home/lkf/.wine/jmzy/drive_c/jmzy_LTLauncher/LTLive.exe"
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
## install_and_start_wine.sh --start XStudio "/data/.home/.wine/XStudio/drive_c/Program Files/NetEase Cloud Music XStudio/NetEase Cloud Music XStudio.exe"
```

#### 三国谋定天下


```bash
%%bash
f=$(find $(pwd) -name "install_and_start_wine.sh" -type f)
echo "$f"
source "$f"
install_to_wine sgmdtx cjkfonts dxvk vcrun2019 dotnet48 corefonts

## ## run in terminal
## install_and_start_wine.sh --start sgmdtx "/data/.home/.wine/sgmdtx/drive_c/Program Files/bilibili Game/NSLG/NSLG.exe"
```

#### 微信


```bash
%%bash
f=$(find $(pwd) -name "install_and_start_wine.sh" -type f)
echo "$f"
source "$f"
install_to_wine wechat vcrun2019 cjkfonts

## ## run in terminal
## install_and_start_wine.sh --start wechat "/data/.home/.wine/wechat/drive_c/Program Files/Tencent/Weixin/Weixin.exe"
```

## 步骤14: 安装 yabridge


```bash
%%bash
echo "Installing yabridge..."
sudo pacman -S --noconfirm --needed yabridgectl >/dev/null
```
