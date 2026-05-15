#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while IFS= read -r f; do
    source "$f"
done < <(find "$SCRIPT_DIR/lib" -name '*.sh' -type f)
