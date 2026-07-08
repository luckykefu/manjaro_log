```bash
sudo pacman -S --noconfirm --needed waydroid
## >>> 更改 Waydroid 数据目录 >>>
mkdir -p /data/.waydroid
sudo rm -fr /var/lib/waydroid 
sudo ln -sf /data/.waydroid /var/lib/waydroid

export all_proxy="socks5h://127.0.0.1:7890"
export https_proxy="socks5h://127.0.0.1:7890"
sudo -E waydroid init -f -s GAPPS
sudo systemctl start waydroid-container.service
# sudo pacman -S --needed --noconfirm bash-dbus
yay -S waydroid-script-git --noconfirm --needed

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
waydroid show-full-ui

# waydroid app install /home/lkf/Downloads/APK/应用宝.apk

waydroid session stop
```
