#!/usr/bin/env bash

chmod_x() {
    find "$1" -type f -name '*.sh' -exec chmod +x {} +
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && chmod_x "$@"