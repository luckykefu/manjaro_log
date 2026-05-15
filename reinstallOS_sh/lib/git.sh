#!/usr/bin/env bash

## Configure git with global settings
## Args: $1 - config dir (default: ~/manjaro-backup), $2 - home dir (default: $HOME)
cmd_git() {
    local CONFIG_DIR="${1:-$HOME/manjaro-backup}"
    local HOME_DIR="${2:-$HOME}"
    local git_config="$CONFIG_DIR/.gitconfig"
    if [[ -f "$git_config" ]]; then
        cp "$git_config" "$HOME_DIR/.gitconfig"
        log_success ".gitconfig copied from $git_config"
    else
        log_warn ".gitconfig not found: $git_config, applying defaults"
        git config --global user.name "${GIT_USER_NAME:-user}"
        git config --global user.email "${GIT_USER_EMAIL:-user@example.com}"
    fi
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    git config --global rebase.autostash true
    git config --global credential.helper store
    git config --global ssh.command "ssh"
    git config --global core.autocrlf input
    git config --global core.filemode false
    log_success "Git configured"
}
