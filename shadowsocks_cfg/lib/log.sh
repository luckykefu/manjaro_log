#!/usr/bin/env bash
set -euo pipefail

info()  { echo -e "\e[1;34m[*]\e[0m $*"; }
ok()    { echo -e "\e[1;32m[✓]\e[0m $*"; }
skip()  { echo -e "\e[1;33m[-]\e[0m $*"; }
err()   { echo -e "\e[1;31m[x]\e[0m $*"; }
