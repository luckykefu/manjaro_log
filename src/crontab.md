# Crontab Usage

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─ day of week (0-7, 0=Sunday)
│ │ │ └─── month (1-12)
│ │ └───── day of month (1-31)
│ └─────── hour (0-23)
└───────── minute (0-59)
```

Examples:
- `*/15 * * * *` - every 15 minutes
- `0 * * * *` - every hour
- `0 2 * * *` - daily at 2am
- `0 9 * * 1-5` - weekdays at 9am
- `0 0 * * 0` - every Sunday at midnight

Commands:
```bash
# list
crontab -l  
# edit
crontab -e  
# remove all
crontab -r 
```

**Note:** Audio commands need `XDG_RUNTIME_DIR=/run/user/$(id -u)`


```python
!crontab -l  # list
```

```python
!crontab -e  # edit
```

```python
!crontab -r  # remove all```

```bash
%%bash
add_cron() {
    local job="$1"
    (crontab -l 2>/dev/null | grep -qF "$job") || (crontab -l 2>/dev/null; echo "$job") | crontab -
}

add_cron "*/5 * * * * XDG_RUNTIME_DIR=/run/user/$(id -u) paplay /usr/share/sounds/freedesktop/stereo/bell.oga"
```
