# AGENTS.md — Manjaro dotfiles & system setup

## Repo overview

Personal Manjaro Linux system configuration, provisioning, and usage notes. Not a software project. No Cargo.toml / CI / tests.

- `reinstall_system/` — full system reinstall from scratch
- `liveOS/` — live USB provisioning (subset of reinstall)
- `kde_config/` — macOS theme, KDE settings, wallpaper, clock
- `wg_cfg/` — WireGuard server + client setup over SSH
- `shadowsocks_cfg/` — SS server deploy, Clash config generation
- `scripts/` — standalone utility scripts (app_update, install_cli_tools, auto_push, git_wkfw, chmod_x, create_timer)
- `usage/` — personal usage notes / tutorials for various tools
- `backup_data/` — exported config backups (KeePassXC, ZeroOmega)
- `docs/` — personal reference documents

## Architecture pattern

Every module follows:
```
module/main.sh          # entrypoint, sources all lib/*.sh, calls main()
module/lib/*.sh         # function definitions, no side effects at top level
```

Shell conventions:
- `set -euo pipefail` at top of every script
- Function + `[[ "${BASH_SOURCE[0]}" == "$0" ]] && func "$@"` double-use guard
- `[[ ]]` over `[ ]`
- Log helpers sourced from `lib/log.sh`: `info()`, `ok()`, `skip()`, `err()`

## Package management

```bash
sudo pacman -S --needed --noconfirm <pkgs>    # system packages
yay -S --needed --noconfirm <pkgs>            # AUR packages
```

Key packages: `base-devel yay keepassxc rust zed opencode alacritty` (system), `clash-verge-rev-bin cryptomator-bin` (AUR).

## Update

```bash
sudo pacman -Syyu --noconfirm && yay -Syyu --noconfirm   # full system upgrade
```

Function defined in `reinstall_system/lib/update.sh`.

## Proxy

Proxy-required operations (theme install, git clone, etc.):
```bash
ALL_PROXY=socks5://127.0.0.1:1080 <command>
```

## Git backup

Systemd user timer pushes daily commits to multiple repos (`.manjaro`, `.cryptomator`, etc.).
- Timer: `~/.config/systemd/user/git-backup.timer` — daily at 00:00
- Script generation: `scripts/create_timer.sh <script_path>`
- Script template: `auto_push.sh` (git add -A, date-stamped commit, push)

## Submodules

- `reinstall_system/lib/.zsh/zsh-sudo` → `none9632/zsh-sudo`

## Sensitive data

- SSH keys committed under `reinstall_system/lib/.ssh/` and `liveOS/lib/.ssh/`
- GPG passphrase `lkf.Gpg.mima3` hardcoded in `reinstall_system/main.sh` and `liveOS/main.sh`
- `.gitignore` only excludes `**/.ssh/` at root, not in subdirs
- `.cryptomator/` is a separate encrypted repo at `/data/.cryptomator/`

## Existing instruction file

`AGENTS_RULES.md` at repo root contains:
- CHAT: Chinese conversation, "需求分析+解决方案" format, confirm before executing, ask before `rm`
- Shell: `pacman -S --needed --noconfirm`, `[[ ]]` over `[ ]`
- README format (Rust-centric, not relevant to this repo)
- Rust coding rules (not relevant — no Cargo.toml in this repo)

## CLI tool conventions (scripts/install_cli_tools.sh)

Replaces classic Unix tools with Rust alternatives:
`bat`→cat, `fd`→find, `rg`→grep, `eza`→ls, `zoxide`→cd, `git-delta`→diff pager, `procs`→ps, `dust`→du, `btm`→htop

Shell completions and git-delta config in `scripts/install_cli_tools.md`.
