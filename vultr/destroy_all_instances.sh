#!/bin/bash

set -euo pipefail

destroy_all_instances() {
    : "${VULTR_API_KEY:?}"
    local base="${API_BASE_URL:-https://api.vultr.com/v2}"
    local ids
    ids=(
        $(curl -s "$base/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[]?.id')
    )
    [[ ${#ids[@]} -eq 0 ]] && echo "No instances found to delete." && return 0

    for id in "${ids[@]}"; do
        curl -X DELETE -H "Authorization: Bearer $VULTR_API_KEY" "$base/instances/$id" -w "%{http_code}" -o /dev/null -s \
            && echo "Deleted $id" \
            || echo "Failed to delete $id"
        sleep 1
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    destroy_all_instances "$@"
fi
