## 安装

```bash
sudo pacman -S --noconfirm --needed waydroid
```

## 更改 Waydroid 数据目录

```bash
mkdir -p /data/.waydroid
sudo rm -fr /var/lib/waydroid
sudo ln -sf /data/.waydroid /var/lib/waydroid
```

## 初始化

```bash
sudo -E waydroid init -f -s GAPPS
sudo systemctl start waydroid-container.service
# sudo pacman -S --needed --noconfirm bash-dbus
yay -S waydroid-script-git --noconfirm --needed
```

## 安装 libhoudini 支持arm

```bash
sudo -E python3 /opt/waydroid-script/main.py -a 13 install libhoudini
# sudo -E python3 /opt/waydroid-script/main.py -a 13 install libndk

#### internet

## >>> 保存 iptables 规则永久生效 >>>
# waydroid_net() {
#     iface=$(ip route | grep default | awk '{print $5}' | head -1)
#     ## 找到你电脑连接互联网的网卡名称（比如 wlan0 或 eth0）

#     sudo iptables -A FORWARD -i waydroid0 -o $iface -j ACCEPT
#     ## 允许 Android 容器的流量转发到外网

#     sudo iptables -A FORWARD -i $iface -o waydroid0 -j ACCEPT
#     ## 允许外网的回复流量转发回 Android 容器

#     sudo iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
#     ## 把 Android 容器的内网 IP 伪装成你电脑的外网 IP（NAT 转换）
# }
# waydroid_net
#
```

## 启动

```bash
waydroid show-full-ui
```

## 安装应用

```bash
waydroid app install /home/lkf/Downloads/sgmdtx_bilibili_1.36.0_20260902_114855.apk
```
