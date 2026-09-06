#!/bin/bash

set -euo pipefail

: "${VULTR_API_KEY:?}" "${TS_AUTHKEY:?}"
API_BASE_URL="https://api.vultr.com/v2"

source "$(dirname "$0")/destroy_all_instances.sh"
source "$(dirname "$0")/create_instance.sh"

case "${1:-}" in
    --destroy-all) destroy_all_instances ;;
    --create) shift; create_instance "$@" ;;
    *) echo "Usage: $0 [--destroy-all | --create [region] [plan] [os_id]]" ;;
esac
