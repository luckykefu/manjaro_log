#!/bin/bash
set -euo pipefail
ip=$1
cd "$(dirname "$0")"
bash ssh_copy_id.sh "$ip"
scp server_deploy.sh "root@${ip}":server_deploy.sh
ssh "root@${ip}" "bash server_deploy.sh"
bash client_cfg.sh $ip
