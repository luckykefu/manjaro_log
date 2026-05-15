#!/usr/bin/env bash

set -euo pipefail

## Brief: Print info-level log message
## Args: $1 - message string
info() {
  printf "\033[1;34m[INFO]\033[0m %s\n" "$*"
}

## Brief: Print warn-level log message
## Args: $1 - message string
warn() {
  printf "\033[1;33m[WARN]\033[0m %s\n" "$*"
}

## Brief: Print error-level log message
## Args: $1 - message string
err() {
  printf "\033[1;31m[ERR]\033[0m %s\n" "$*" >&2
}

## Brief: Print error message and exit with non-zero status
## Args: $1 - message string
die() {
  err "$1"
  exit 1
}
