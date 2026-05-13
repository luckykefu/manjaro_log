# log.zsh — 彩色日志输出工具
# DOC:
#   info  → 蓝色 [*] 信息
#   ok    → 绿色 [✓] 成功
#   skip  → 黄色 [-] 跳过
# 用法: info "message"; ok "done"; skip "not found"

# 蓝色 [*] 信息
info()  { echo -e "\e[1;34m[*]\e[0m $*"; }
# 绿色 [✓] 成功
ok()    { echo -e "\e[1;32m[✓]\e[0m $*"; }
# 黄色 [-] 跳过
skip()  { echo -e "\e[1;33m[-]\e[0m $*"; }
