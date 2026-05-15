#!/usr/bin/env bash

LOG_LEVEL="${LOG_LEVEL:-info}"

## Log an info message
## Args: $1 - message string
log_info() {
    printf "\033[34m[INFO]\033[0m %s\n" "$1"
}

## Log a warning message
## Args: $1 - message string
log_warn() {
    printf "\033[33m[WARN]\033[0m %s\n" "$1"
}

## Log an error message
## Args: $1 - message string
log_error() {
    printf "\033[31m[ERROR]\033[0m %s\n" "$1"
}

## Log a debug message
## Args: $1 - message string
log_debug() {
    if [[ "$LOG_LEVEL" == "debug" ]]; then
        printf "\033[36m[DEBUG]\033[0m %s\n" "$1"
    fi
}

## Log a success message
## Args: $1 - message string
log_success() {
    printf "\033[32m[SUCCESS]\033[0m %s\n" "$1"
}

## Run a command, log it, return its exit code
## Args: $@ - command and arguments to run
run_cmd() {
    log_info "Running: $*"
    "$@"
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        log_error "Command failed with exit code $ret: $*"
    fi
    return $ret
}

## Create a symbolic link with backup of existing target
## Args: $1 - source path, $2 - target path
sf_link_mk() {
    local src="${1?}"
    local tgt="${2?}"
    if [[ -e "$tgt" ]] || [[ -L "$tgt" ]]; then
        local backup="${tgt}.bak.$(date +%Y%m%d%H%M%S)"
        log_info "Backing up $tgt to $backup"
        mv "$tgt" "$backup"
    fi
    ln -s "$src" "$tgt"
    log_success "Created symlink: $tgt -> $src"
}
