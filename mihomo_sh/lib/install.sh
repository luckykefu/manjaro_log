install() {
  command -v mihomo &>/dev/null && sinfo "[install] mihomo already installed: $(mihomo -v 2>/dev/null | head -1)" && return 0
  sinfo "[install] installing mihomo..."
  sudo pacman -S --needed --noconfirm archlinuxcn/mihomo || { serror "[install] failed to install mihomo"; return 1; }
  sinfo "[install] mihomo installed"
}
