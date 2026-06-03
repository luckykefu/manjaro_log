## Shell RULES

- `sudo pacman -S --needed --noconfirm <pkgs>`
- `yay -S --needed --noconfirm <pkgs>`
- jq for json
- yq for yaml
- fmt tool: shellcheck

## sh script tmp

- using [[]], not []
- using && ||,not if then fi

```bash
#! /usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$BASH_SOURCE" != "$0" ]]; then
    main "$@"
fi
```
