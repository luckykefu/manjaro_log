#### opencl driver


```bash
%%bash
sudo pacman -S --needed --noconfirm rocm-opencl-runtime
```

```bash
%%bash
yes | sudo $HOME/Downloads/DaVinci_Resolve_20.3.1_Linux/DaVinci_Resolve_20.3.1_Linux.run -i
##  /opt/resolve/bin/resolve: error while loading shared libraries: libcrypt.so.1: cannot open shared object file: No such file or directory
sudo pacman -S --needed --noconfirm libxcrypt-compat lib32-libxcrypt-compat
## /opt/resolve/bin/resolve: symbol lookup error: /usr/lib/libpango-1.0.so.0: undefined symbol: g_once_init_leave_pointer
LD_PRELOAD="/usr/lib/libgio-2.0.so /usr/lib/libgmodule-2.0.so /usr/lib/libglib-2.0.so" /opt/resolve/bin/resolve

#### Q
```
