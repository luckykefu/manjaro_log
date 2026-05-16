#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" && pwd

while IFS= read -r f; do
    source "$f"
done < <(find "lib" -name '*.sh' -type f)
