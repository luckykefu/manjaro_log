#!/bin/bash
# lib/common.sh
# 通用函数库: 日志/命令执行/SCP/SSH

LOG_LEVEL=${LOG_LEVEL:-0}
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

_log_enabled() {
    [[ $1 -ge $LOG_LEVEL ]]
}

_log_color() {
    case $1 in
        0) echo -e "\e[0;36m" ;;  # DEBUG 青色
        1) echo -e "\e[0;32m" ;;  # INFO  绿色
        2) echo -e "\e[0;33m" ;;  # WARN  黄色
        3) echo -e "\e[0;31m" ;;  # ERROR 红色
        *) echo -e "\e[0m" ;;
    esac
}

_log_level_str() {
    case $1 in
        0) echo "DEBUG" ;;
        1) echo "INFO"  ;;
        2) echo "WARN"  ;;
        3) echo "ERROR" ;;
        *) echo "UNKN"  ;;
    esac
}

sdebug() {
    _log_enabled $LOG_DEBUG || return 0
    local c=$(_log_color $LOG_DEBUG)
    local r="\e[0m"
    echo -e "${c}DEBUG${r} ${FUNCNAME[1]:-main}: $*"
}

sinfo() {
    _log_enabled $LOG_INFO || return 0
    local c=$(_log_color $LOG_INFO)
    local r="\e[0m"
    echo -e "${c}INFO${r} ${FUNCNAME[1]:-main}: $*"
}

swarn() {
    _log_enabled $LOG_WARN || return 0
    local c=$(_log_color $LOG_WARN)
    local r="\e[0m"
    echo -e "${c}WARN${r} ${FUNCNAME[1]:-main}: $*"
}

serror() {
    _log_enabled $LOG_ERROR || return 0
    local c=$(_log_color $LOG_ERROR)
    local r="\e[0m"
    echo -e "${c}ERROR${r} ${FUNCNAME[1]:-main}: $*"
}

step() {
    local c="\e[0;36m"
    local r="\e[0m"
    echo -e "${c}[$1/$2]${r} $3"
}

ok() {
    local c="\e[0;32m"
    local r="\e[0m"
    echo -e "${c}✓${r} $*"
}

info() {
    local c="\e[0;34m"
    local r="\e[0m"
    echo -e "${c}ℹ${r} $*"
}

run() {
    local out
    out=$(eval "$@" 2>&1) || {
        sdebug "run failed: $* -> $out"
        return 1
    }
    echo "$out"
}

sudo() {
    local out
    out=$(command sudo "$@" 2>&1) || {
        sdebug "sudo failed: $* -> $out"
        return 1
    }
    echo "$out"
}

bash_exec() {
    local out
    out=$(bash -c "$*" 2>&1) || {
        sdebug "bash_exec failed: $* -> $out"
        return 1
    }
    echo "$out"
}

sudo_bash_exec() {
    local out
    out=$(sudo bash -c "$*" 2>&1) || {
        sdebug "sudo_bash_exec failed: $* -> $out"
        return 1
    }
    echo "$out"
}

sudo_ignore_output() {
    sudo "$@" >/dev/null 2>&1
}

scp() {
    local src=$1 dst=$2
    local out
    out=$(command scp -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$src" "$dst" 2>&1) || {
        sdebug "scp failed: $src -> $dst: $out"
        return 1
    }
    echo "$out"
}

ssh() {
    local host=$1 cmd=$2
    local out
    out=$(command ssh -o ConnectTimeout=5 "$host" "$cmd" 2>&1) || {
        sdebug "ssh $host failed: $out"
        return 1
    }
    echo "$out"
}
