#!/bin/bash
path_append() {
	local tgt=${1:-}
	[[ -z "$tgt" ]] && return 1

	local e_l="export PATH=\"$tgt:\$PATH\""
	if grep -qF "$e_l" "$HOME/.zshrc"; then
		echo "  ✓ PATH already contains $tgt"
	else
		echo "$e_l" >>"$HOME/.zshrc"
		echo "  ✓ Added $tgt to PATH"
	fi
}

source_append() {
	local tgt=${1:-}
	local s_l="source $tgt"

	if grep -qF "$s_l" "$HOME/.zshrc"; then
		echo "  ✓ Already sourcing $tgt"
	else
		echo "$s_l" >>"$HOME/.zshrc"
		echo "  ✓ Added source $tgt"
	fi
	source "$HOME/.zshrc" &>/dev/null
}
