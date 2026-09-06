#!/usr/bin/env bash
ip=${1:?ip}
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
f=server.sh
scp "$DIR/$f" "root@${ip}":~/
ssh "root@${ip}" "bash ~/$f"
