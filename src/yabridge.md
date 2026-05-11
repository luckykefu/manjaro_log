### install


```bash
%%bash
sudo pacman -Sy --needed --noconfirm yabridge yabridgectl wine wine-gecko wine-mono winetricks
```

### vst


#### 虚拟桌面组


```bash
%%bash
vst3="/data/.wine/vst/virtualdesktop/drive_c/Program Files/Common Files/VST3"
yabridgectl add "$vst3"
vst2="/data/.wine/vst/virtualdesktop/drive_c/Program Files/Steinberg/VSTPlugins"
yabridgectl add "$vst2"

yabridgectl list

yabridgectl sync --pured
```

```bash
%%bash
t="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$t" winecfg
WINEPREFIX="$t" winetricks dxvk mfc42
```

#### BABY Audio

虚拟桌面组


```bash
%%bash
d=$(find /data/vst -type d -name "BABY Audio" -maxdepth 1)
echo "$d"
[[ -d "$d/C/Users" ]] && mv -f "$d/C/Users" "$d/C/users"
[[ -d "$d/C/users" ]] && mv -f "$d/C/users"/* "$d/C/users/$USER"
```

```bash
%%bash
d="/data/vst/BABY Audio/C"
t="/data/.wine/vst/virtualdesktop/drive_c"
cp -rf "$d"/* "$t"
```

| 插件品牌   | 插件名称                | 功能             |
| ---------- | ----------------------- | ---------------- |
| BABY Audio | TAIP.vst3               | 磁带模拟         |
| BABY Audio | Transit.vst3            | 过渡效果器       |
| BABY Audio | Crystalline.vst3        | 晶体混响         |
| BABY Audio | SpacedOut.vst3          | 空间效果器       |
| BABY Audio | ParallelAggressor.vst3  | 并行压缩/失真    |
| BABY Audio | Keylay.vst3             | 键控效果器       |
| BABY Audio | Pitch Drift.vst3        | 音高漂移         |
| BABY Audio | BA-1.vst3               | 多效果器         |
| BABY Audio | IHeartNY.vst3           | 并行压缩         |
| BABY Audio | IHNY-2.vst3             | 并行压缩(升级版) |
| BABY Audio | SuperVHS.vst3           | VHS 模拟效果器   |
| BABY Audio | SmoothOperator.vst3     | 智能均衡器       |
| BABY Audio | MagicSwitch.vst3        | 一键增强效果器   |
| BABY Audio | ComebackKid.vst3        | 延迟效果器       |
| BBE Sound  | Sonic Maximizer.vst3    | 音频增强器       |
| BBE Sound  | Mach 3 Bass.vst3        | 低音增强器       |
| BBE Sound  | Loudness Maximizer.vst3 | 响度最大化器     |
| BBE Sound  | Harmonic Maximizer.vst3 | 谐波增强器       |
| BBE Sound  | Soul Vibe.vst3          | 颤音效果器       |
| BBE Sound  | Sonic Stomp.vst3        | 吉他效果器       |
| BBE Sound  | Mind Bender.vst3        | 相位效果器       |
| BBE Sound  | Tremor.vst3             | 震音效果器       |
| BBE Sound  | Opto Stomp.vst3         | 光学压缩效果器   |
| BBE Sound  | Free Fuzz.vst3          | 模糊失真效果器   |
| BBE Sound  | Stomp Board.vst3        | 多效果器踏板     |
| BBE Sound  | Two Timer.vst3          | 双延迟效果器     |
| BBE Sound  | Green Screamer.vst3     | 过载效果器       |


#### dadalife

虚拟桌面组+dxvk 组


```bash
%%bash
e=$(find /data/vst -type f -name "DADALIFE_Sausage_Fattener_1.4.1_MOCHA.exe")
echo "$e"
t="/data/.wine/vst/virtualdesktop"

WINEPREFIX="$t" wine "$e"
```

#### fabfilter

虚拟桌面 组


```bash
%%bash
e=$(find /data/vst -type f -name "Install_64bit_VST3_Effects.cmd")
echo "$e"
t="/data/.wine/vst/virtualdesktop"
dir=$(dirname "$e")
cd "$dir"
WINEPREFIX="$t" wine cmd /c "$e"
c=$(find /data/vst -type f -name "FabFilter_KeyGen.exe")
WINEPREFIX="$t" wine "$c"
```

#### Harman Audio

虚拟桌面 + mfc42 组


```bash
%%bash
e=$(find /data/vst -type f -name "Setup LXP Native Reverb v1.2.2.exe")
w="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$w" wine "$e"
## winetricks mfc42
## drive_c/Program Files/Steinberg/VSTPlugins/
```

| 插件品牌 | 插件名称               | 功能           |
| -------- | ---------------------- | -------------- |
| Lexicon  | LXPHall.dll            | 大厅混响       |
| Lexicon  | LXPChamber.dll         | 室内混响       |
| Lexicon  | LXPRoom.dll            | 房间混响       |
| Lexicon  | LXPPlate.dll           | 板式混响       |
| Lexicon  | LexPitchShift.dll      | 音高移位       |
| Lexicon  | LexResonantChords.dll  | 共振和弦       |
| Lexicon  | LexMultivoicePitch.dll | 多声部音高处理 |
| Lexicon  | LexStringBox.dll       | 弦乐效果器     |
| Lexicon  | LexRandomDelay.dll     | 随机延迟       |
| Lexicon  | LexDualDelay.dll       | 双延迟         |
| Lexicon  | LexChorus.dll          | 合唱效果器     |


```bash
%%bash
e=$(find /data/vst -type f -name "Setup PCM Native Effects v1.2.6.exe")
w="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$w" wine "$e"
## winetricks mfc42
## drive_c/Program Files/Steinberg/VSTPlugins/
```

#### ikmultimedia

虚拟桌面组


```bash
%%bash
## IK_Multimedia_Keygen.exe
## Setup T-RackS 6 v6.0.2.exe
e=$(find /data/vst -type f -name "Setup T-RackS 6 v6.0.2.exe")
echo "$e"
t="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$t" wine "$e"
c="$(find /data/vst -type f -name "IK_Multimedia_Keygen.exe")"
echo "$c" && WINEPREFIX="$t" wine "$c"
```

#### okesound

虚拟桌面组


```bash
%%bash
d="/data/vst/Oeksound/C"
t="/data/.wine/vst/virtualdesktop/drive_c"
cp -rf "$d"/* "$t"
```

#### slatedigital

虚拟桌面组


```bash
%%bash
## License Support Win64.exe
## fresh-air-win-1.1.1.exe

e=$(find /data/vst -type f -name "License Support Win64.exe")
echo "$e"
t="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$t" wine "$e"
unset e

e=$(find /data/vst -type f -name "fresh-air-win-1.1.1.exe")
echo "$e"
WINEPREFIX="$t" wine "$e"
```

#### ssl

虚拟桌面组


```bash
%%bash
## Solid State Logic
d="/data/vst/Solid State Logic"
[[ -d "$d/C/Users" ]] && mv -f "$d/C/Users" "$d/C/users"
[[ -d "$d/C/users" ]] && mv -f "$d/C/users"/* "$d/C/users/$USER"
t="/data/.wine/vst/virtualdesktop/drive_c"
cp -r "$d/C"/* "$t"
```

#### sonible

虚拟桌面组


```bash
%%bash
e=$(find /data/vst -type f -name "Sonible full bundle 2023.3 CE.exe")
echo "$e"
t="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$t" wine "$e"
```

#### ValhallaDSP

虚拟桌面组


```bash
%%bash
e=$(find /data/vst -type f -name "ValhallaDSP bundle 2024.3 CE.exe")
echo "$e"
t="/data/.wine/vst/virtualdesktop"
WINEPREFIX="$t" wine "$e"
```

#### wavesfactory


```bash
%%bash
d="/data/vst/Wavesfactory - Plugins Bundle [07.2023]"
t="/data/.wine/vst/virtualdesktop"
for f in "$d"/*.exe; do
	echo "$f"
	WINEPREFIX="$t" wine "$f"
done
```

```bash
%%bash
t="/data/.wine/vst/virtualdesktop"
e=$(find /data/vst -type f -name "WavesFactory_KeyGen.exe")
echo "$e"
WINEPREFIX="$t" wine "$e"
```

### ERROR


#### 插件界面可见且有声音，但鼠标点击位置偏移或完全无效


```python
## 打开终端，输入 winecfg。
## 切换到 显示 (Graphics) 选项卡。
## 勾选 “模拟一个虚拟桌面” (Emulate a virtual desktop)。
## 设置一个合适的分辨率（如 1024x768）。
## 点击 “应用” (Apply) 按钮。
```

#### 安装失败


```python
winetricks mfc42
```
