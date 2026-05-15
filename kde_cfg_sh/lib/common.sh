#!/usr/bin/env bash
## Brief: Shared logging and utility functions

LOG_LEVEL="${LOG_LEVEL:-info}"

log_debug() { if [[ "${LOG_LEVEL}" =~ ^(debug)$ ]]; then printf "\033[36m[DEBUG]\033[0m %s\n" "$*" >&2; fi; }
log_info()  { if [[ "${LOG_LEVEL}" =~ ^(debug|info)$ ]]; then printf "\033[34m[INFO]\033[0m  %s\n" "$*"; fi; }
log_warn()  { printf "\033[33m[WARN]\033[0m  %s\n" "$*" >&2; }
log_error() { printf "\033[31m[ERROR]\033[0m %s\n" "$*" >&2; }
log_success() { printf "\033[32m[OK]\033[0m    %s\n" "$*"; }

exec_cmd() {
  ## Brief: Run a command with logging
  ## Args: command and arguments
  log_debug "Running: $*"
  "$@"
  local ret=$?
  if [[ $ret -ne 0 ]]; then
    log_warn "Command exited with code $ret: $*"
  fi
  return $ret
}
